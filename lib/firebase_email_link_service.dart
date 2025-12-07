import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase Email Link Authentication
/// هذه الخدمة تدير عملية المصادقة عبر رابط البريد الإلكتروني
class FirebaseEmailLinkService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // مفاتيح التخزين المحلي
  static const String _emailKey = 'pending_email_verification';

  /// إرسال رابط التحقق إلى البريد الإلكتروني
  ///
  /// [email] - البريد الإلكتروني للمستخدم
  /// [continueUrl] - الرابط الذي سيعود إليه المستخدم بعد التحقق
  ///
  /// Returns: Map<String, dynamic> يحتوي على حالة النجاح والرسالة
  static Future<Map<String, dynamic>> sendSignInLinkToEmail({
    required String email,
    String? continueUrl,
  }) async {
    try {
      // إعدادات رابط التحقق
      final actionCodeSettings = ActionCodeSettings(
        // الرابط الذي سيعود إليه المستخدم بعد النقر على الرابط في البريد
        url: continueUrl ?? 'https://minexsy.site/verify-email',

        // يجب أن يكون true لفتح الرابط في التطبيق
        handleCodeInApp: true,

        // إعدادات Android
        androidPackageName: 'site.minexsy.minex_syrian_arab',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      // إرسال رابط التحقق
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // حفظ البريد الإلكتروني محلياً للاستخدام لاحقاً
      await _saveEmailForVerification(email);

      if (kDebugMode) {
        debugPrint('✅ تم إرسال رابط التحقق إلى: $email');
      }

      return {
        'success': true,
        'message':
            'تم إرسال رابط التحقق إلى بريدك الإلكتروني. الرجاء فتح البريد والضغط على الرابط.',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ Firebase: ${e.code} - ${e.message}');
      }

      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'هذا الحساب معطل';
          break;
        case 'too-many-requests':
          errorMessage = 'تم إرسال عدد كبير من الطلبات. يرجى المحاولة لاحقاً';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء إرسال رابط التحقق: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ غير متوقع: $e');
      }

      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      };
    }
  }

  /// التحقق من الرابط وتسجيل الدخول
  ///
  /// [emailLink] - الرابط الذي تم استلامه في البريد الإلكتروني
  /// [email] - البريد الإلكتروني (اختياري إذا كان محفوظ محلياً)
  ///
  /// Returns: Map<String, dynamic> يحتوي على حالة النجاح وبيانات المستخدم
  static Future<Map<String, dynamic>> signInWithEmailLink({
    required String emailLink,
    String? email,
  }) async {
    try {
      // التحقق من أن الرابط صالح
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        return {
          'success': false,
          'message': 'الرابط غير صالح أو منتهي الصلاحية',
        };
      }

      // الحصول على البريد المحفوظ إذا لم يتم توفيره
      String? verificationEmail = email;
      if (verificationEmail == null || verificationEmail.isEmpty) {
        verificationEmail = await _getSavedEmail();
        if (verificationEmail == null) {
          return {
            'success': false,
            'message': 'يرجى إدخال البريد الإلكتروني للمتابعة',
            'needsEmail': true,
          };
        }
      }

      // تسجيل الدخول باستخدام الرابط
      final UserCredential userCredential = await _auth.signInWithEmailLink(
        email: verificationEmail,
        emailLink: emailLink,
      );

      // مسح البريد المحفوظ
      await _clearSavedEmail();

      if (kDebugMode) {
        debugPrint('✅ تم تسجيل الدخول بنجاح: ${userCredential.user?.email}');
      }

      return {
        'success': true,
        'message': 'تم التحقق من البريد الإلكتروني وتسجيل الدخول بنجاح',
        'user': {
          'uid': userCredential.user?.uid,
          'email': userCredential.user?.email,
          'emailVerified': userCredential.user?.emailVerified,
          'isNewUser': userCredential.additionalUserInfo?.isNewUser ?? false,
        },
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ Firebase: ${e.code} - ${e.message}');
      }

      String errorMessage;
      switch (e.code) {
        case 'expired-action-code':
          errorMessage = 'انتهت صلاحية الرابط. يرجى طلب رابط جديد';
          break;
        case 'invalid-action-code':
          errorMessage = 'الرابط غير صالح أو تم استخدامه بالفعل';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'هذا الحساب معطل';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء التحقق: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'code': e.code,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطأ غير متوقع: $e');
      }

      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
      };
    }
  }

  /// ربط حساب موجود برابط البريد الإلكتروني
  ///
  /// يستخدم هذا لإضافة طريقة مصادقة جديدة لحساب موجود
  static Future<Map<String, dynamic>> linkWithEmailLink({
    required String emailLink,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'لا يوجد مستخدم مسجل حالياً',
        };
      }

      // إنشاء بيانات الاعتماد من الرابط
      final AuthCredential credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: emailLink,
      );

      // ربط بيانات الاعتماد بالحساب الحالي
      await user.linkWithCredential(credential);

      return {
        'success': true,
        'message': 'تم ربط البريد الإلكتروني بالحساب بنجاح',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'provider-already-linked':
          errorMessage = 'هذا البريد مرتبط بالحساب بالفعل';
          break;
        case 'invalid-credential':
          errorMessage = 'بيانات الاعتماد غير صالحة';
          break;
        case 'credential-already-in-use':
          errorMessage = 'هذا البريد مستخدم من قبل حساب آخر';
          break;
        default:
          errorMessage = 'حدث خطأ أثناء الربط: ${e.message}';
      }

      return {
        'success': false,
        'message': errorMessage,
        'code': e.code,
      };
    }
  }

  /// التحقق من أن المستخدم الحالي قد تم التحقق من بريده
  static Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // تحديث معلومات المستخدم
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// الحصول على المستخدم الحالي
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// تسجيل الخروج
  static Future<void> signOut() async {
    await _auth.signOut();
    await _clearSavedEmail();
  }

  // === دوال التخزين المحلي ===

  /// حفظ البريد الإلكتروني محلياً
  static Future<void> _saveEmailForVerification(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_emailKey, email);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ خطأ في حفظ البريد: $e');
      }
    }
  }

  /// الحصول على البريد المحفوظ
  static Future<String?> _getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ خطأ في قراءة البريد: $e');
      }
      return null;
    }
  }

  /// مسح البريد المحفوظ
  static Future<void> _clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emailKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ خطأ في مسح البريد: $e');
      }
    }
  }

  /// الحصول على البريد المحفوظ (عامة للاستخدام في الصفحات)
  static Future<String?> getSavedEmail() async {
    return _getSavedEmail();
  }
}
