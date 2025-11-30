import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  static String baseUrl = 'https://minexsy.site';

  // مفاتيح التخزين المحلي
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userGenderKey = 'user_gender';
  static const String _userIsAdminKey = 'user_is_admin';
  static const String _userTypeKey = 'user_type';

  // نموذج المستخدم
  static Map<String, dynamic>? _currentUser;
  static String? _userToken;
  static String? _currentToken;

  // الحصول على التوكن
  static Future<String?> getToken() async {
    if (_currentToken == null) {
      await loadUserData();
    }
    return _currentToken;
  }

  // الحصول على المستخدم الحالي
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get currentToken => _currentToken;
  static bool get isLoggedIn => _currentToken != null && _currentUser != null;

  // التحقق من صحة المشرف
  static bool get isAdmin {
    if (_currentUser != null && _currentUser!.containsKey('is_admin')) {
      return _currentUser!['is_admin'] == 1;
    }
    return false;
  }

  // التحقق من صلاحيات الإدارة قبل تنفيذ العمليات الحساسة
  static bool checkAdminPermissions() {
    if (!isLoggedIn) {
      return false;
    }
    return isAdmin;
  }

  // إنشاء ترويسات HTTP موحدة
  static Map<String, String> getHeaders([String? token]) {
    Map<String, String> headers = {'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // معالج الاستجابة الموحد
  // معالج الاستجابة الموحد والمحسّن
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String action,
  ) {
    // طباعة التفاصيل الكاملة للمطور فقط في الـ Console
    print('📥 استجابة $action:');
    print('Status Code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    print('Body: ${response.body}');

    // حاول تحليل الـ JSON
    try {
      final dynamic body = json.decode(response.body);

      // إذا كان الجسم كائن JSON صالح، أعده كما هو
      if (body is Map<String, dynamic>) {
        // التأكد من أن الرسالة التي للمستخدم بسيطة
        if (body['message'] != null &&
            body['message'].toString().length > 100) {
          body['message'] = 'حدث خطأ، يرجى المحاولة مرة أخرى.';
        }
        return body;
      }
    } catch (e) {
      print(' خطأ في تحليل JSON: $e'); // طباعة الخطأ الحقيقي للمطور
    }

    // إذا فشل التحليل، أنشئ رسالة خطأ بسيطة للمستخدم
    String userMessage = 'حدث خطأ، يرجى المحاولة لاحقًا.';

    // تحديد رسالة بناءً على كود الحالة (لأهم الأخطاء)
    if (response.statusCode == 404) {
      userMessage = 'الصفحة المطلوبة غير موجودة.';
    } else if (response.statusCode == 401) {
      userMessage = 'جلسة منتهية، يرجى إعادة تسجيل الدخول.';
    } else if (response.statusCode == 403) {
      userMessage = 'ليس لديك صلاحية للقيام بهذه العملية.';
    } else if (response.statusCode >= 500) {
      userMessage = 'خدمة غير متوفرة حاليًا، يرجى المحاولة لاحقًا.';
    }

    return {
      'success': false,
      'message': userMessage, // رسالة بسيطة للمستخدم
      'data': null,
    };
  }

  //  دالة محسنة لإنشاء منشور مع دعم الصور والفيديوهات
  static Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String content,
    String? price,
    String? location,
    List<String>? imagePaths,
    String? videoPath,
  }) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/posts/create'),
      );

      // إضافة الترويسات
      if (token != null) {
        request.headers.addAll(getHeaders(token));
      }

      // إضافة البيانات النصية
      request.fields['title'] = title;
      request.fields['category'] = category;
      request.fields['content'] = content;
      if (price != null && price.isNotEmpty) {
        request.fields['price'] = price;
      }
      if (location != null && location.isNotEmpty) {
        request.fields['location'] = location;
      }

      // إضافة الصور
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          var file = await http.MultipartFile.fromPath(
            'images[]',
            imagePaths[i],
          );
          request.files.add(file);
        }
      }

      // إضافة الفيديو
      if (videoPath != null && videoPath.isNotEmpty) {
        var videoFile = await http.MultipartFile.fromPath(
          'video',
          videoPath,
        );
        request.files.add(videoFile);
      }

      print('📤 إرسال طلب إنشاء منشور...');
      print('URL: ${request.url}');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.length} ملف');

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response, 'create_post');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  //  دالة محسنة لجلب المنشورات
  static Future<Map<String, dynamic>> getPosts() async {
    try {
      final token = await getToken();
      final response = await http
          .get(Uri.parse('$baseUrl/api/posts'), headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_posts');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // حذف منشور
  static Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/posts/delete?post_id=$postId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'deletePost');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب الفئات
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      //  تم التعديل: تغيير الرابط إلى /api/categories
      final response = await http
          .get(Uri.parse('$baseUrl/api/categories'))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getCategories');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب الإعلانات المميزة
  static Future<Map<String, dynamic>> getVipAds() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      final response = await http
          .get(Uri.parse('$baseUrl/api/vip-ads'), headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getVipAds');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== العمليات الأساسية ========

  // تسجيل مستخدم جديد
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String emailOrPhone,
    required String password,
    required String gender,
    String? userType,
  }) async {
    try {
      // === جلب device token مع طلب الإذن إذا لزم ===
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken == null) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          deviceToken = await FirebaseMessaging.instance.getToken();
        }
      } catch (e) {
        // طباعة الخطأ الحقيقي للمطور في الـ Console
        print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

        String userMessage =
            'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

        // تحديد نوع الخطأ بناءً على نص الاستثناء
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('socketexception') ||
            errorString.contains('connection refused')) {
          userMessage =
              'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
        } else if (errorString.contains('timeout')) {
          userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
        } else if (errorString.contains('failed to fetch')) {
          userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
        }

        return {
          'success': false,
          'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
        };
      }

      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      // === إعداد بيانات الطلب ===
      final Map<String, String> requestData = {
        'full_name': fullName,
        'email_or_phone': formattedEmailOrPhone,
        'password': password,
        'gender': gender,
      };

      //  إضافة userType إذا وُجد
      if (userType != null) {
        requestData['userType'] = userType;
      }

      //  إضافة device_token إلى الطلب (هذا هو المفتاح!)
      if (deviceToken != null) {
        requestData['device_token'] = deviceToken;
        print('📱 device_token المرسل: $deviceToken');
      } else {
        print('⚠️ device_token غير متوفر عند التسجيل');
      }

      // === إرسال طلب التسجيل ===
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/register'),
            headers: getHeaders(),
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'register');

      // === معالجة النجاح ===
      if (result['success'] == true) {
        await _saveUserData(result['data']);

        // تحديث بيانات المستخدم من الخادم (لضمان تزامن device_token إن تم حفظه لاحقًا)
        try {
          final profileResult = await getProfile();
          if (profileResult['success'] == true) {
            await _saveUserData(profileResult['data']);
          }
        } catch (e) {
          print('⚠️ تعذر جلب الملف الشخصي بعد التسجيل');
        }

        return {
          'success': true,
          'message': result['message'] ?? 'تم التسجيل بنجاح',
          'user': _currentUser,
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // تسجيل دخول المستخدم
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      // جلب توكن الإشعارات من Firebase
      String? deviceToken;
      try {
        deviceToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print("⚠️ Failed to get FCM token");
      }
      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        // التحقق من صحة رقم الهاتف
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      final Map<String, String> requestData = {
        'email_or_phone': formattedEmailOrPhone,
        'password': password,
      };

      if (deviceToken != null) requestData['device_token'] = deviceToken;

      print('📤 إرسال طلب تسجيل الدخول...');
      print('URL: $baseUrl/api/login');
      print('البيانات: ${json.encode({...requestData, 'password': '***'})}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {
              ...getHeaders(),
            },
            body: requestData, // إرسال كـ form-data
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'login');

      if (result['success'] == true) {
        await _saveUserData(result['data']);
        return {
          'success': true,
          'message': result['message'] ?? 'تم تسجيل الدخول بنجاح',
          'user': result['data'],
        };
      }

      return result;
    } catch (e) {
      print(' خطأ في تسجيل الدخول');
      if (e.toString().contains('Failed to fetch')) {
        return {'success': false, 'message': '.تعذّر الاتصال بالخادم'};
      }
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالخادم: ${e.toString()}',
      };
    }
  }

  // التحقق من صحة التوكن
  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'لا يوجد توكن محفوظ'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/verify_token'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'verify_token');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // استعادة كلمة المرور

  static Future<Map<String, dynamic>> forgotPassword({
    required String emailOrPhone,
  }) async {
    try {
      String formattedEmailOrPhone = emailOrPhone;
      if (!isEmail(emailOrPhone)) {
        formattedEmailOrPhone = formatPhoneNumber(emailOrPhone);
        if (!isValidPhone(emailOrPhone)) {
          return {'success': false, 'message': 'رقم الهاتف غير صحيح'};
        }
      } else if (!isValidEmail(emailOrPhone)) {
        return {'success': false, 'message': 'البريد الإلكتروني غير صحيح'};
      }

      final Map<String, String> requestData = {
        'email_or_phone': formattedEmailOrPhone,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/forgot-password'),
            headers: {...getHeaders()},
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'forgot_password');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب الملف الشخصي

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 جلب الملف الشخصي...');
      final response = await http
          .get(Uri.parse('$baseUrl/api/profile'), headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'profile');

      //  إذا نجحت العملية، قم بحفظ البيانات المحدثة
      if (result['success'] == true && result['data'] != null) {
        await _saveUserData(result['data']);

        //  إرجاع البيانات المحدثة من الذاكرة المحلية
        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب البيانات بنجاح',
          'data': _currentUser,
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // تحديث الملف الشخصي
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? gender,
  }) async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }
      final Map<String, String> requestData = {'full_name': fullName};

      // إذا تم توفير الجنس، قم بتحويله وإضافته
      if (gender != null && gender.isNotEmpty) {
        requestData['gender'] = _convertGenderToEnglish(gender);
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/profile/update'),
            headers: {
              ...getHeaders(token),
            },
            body: requestData, // إرسال كـ form-data
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'update_profile');

      if (result['success'] == true && result['data'] != null) {
        // الخادم يعيد بيانات المستخدم المحدثة، نقوم بحفظها مباشرة
        await _saveUserData(result['data']);
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // تغيير كلمة المرور
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final Map<String, String> requestData = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/change-password'),
            headers: {...getHeaders(token)},
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'change_password');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // حذف الحساب (افترضنا الرابط بناءً على المنطق)
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null || _currentUser == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final response = await http
          .delete(Uri.parse('$baseUrl/api/profile'), headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'delete_account');

      if (result['success'] == true) {
        await logout();
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دوال التخزين المحلي ========

  // حفظ بيانات المستخدم
  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = userData['token'];
      _currentUser = {
        'user_id': userData['user_id'],
        'full_name': userData['full_name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'gender': userData['gender'],
        'user_type': userData['user_type'] ?? 'person',
        'is_admin': userData['is_admin'] ?? 0,
      };

      await prefs.setString(_tokenKey, _currentToken!);
      await prefs.setInt(_userIdKey, userData['user_id']);
      await prefs.setString(_userNameKey, userData['full_name']);
      if (userData['email'] != null) {
        await prefs.setString(_userEmailKey, userData['email']);
      }
      if (userData['phone'] != null) {
        await prefs.setString(_userPhoneKey, userData['phone']);
      }
      await prefs.setString(_userGenderKey, userData['gender']);
      await prefs.setString(
        _userTypeKey,
        userData['user_type'] ?? 'person',
      );
      await prefs.setInt(_userIsAdminKey, userData['is_admin'] ?? 0);

      print(' تم حفظ بيانات المستخدم محلياً');
    } catch (e) {
      print(' خطأ في حفظ بيانات المستخدم');
    }
  }

  // تحميل بيانات المستخدم
  static Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString(_tokenKey);
      if (_currentToken != null) {
        _currentUser = {
          'user_id': prefs.getInt(_userIdKey),
          'full_name': prefs.getString(_userNameKey),
          'email': prefs.getString(_userEmailKey),
          'phone': prefs.getString(_userPhoneKey),
          'gender': prefs.getString(_userGenderKey),
          'user_type': prefs.getString(_userTypeKey) ??
              'person', // <-- ✨ أضف هذا السطر مع قيمة افتراضية
          'is_admin': prefs.getInt(_userIsAdminKey) ?? 0,
        };
        print(' تم تحميل بيانات المستخدم من التخزين المحلي');
      }
    } catch (e) {
      print(' خطأ في تحميل بيانات المستخدم');
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentToken = null;
      _currentUser = null;
      print(' تم تسجيل الخروج وحذف البيانات المحلية');
    } catch (e) {
      print(' خطأ في تسجيل الخروج');
    }
  }

  // ======== دوال التحقق والتنسيق ========

  // التحقق من صحة البريد الإلكتروني
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // التحقق من صحة رقم الهاتف
  static bool isValidPhone(String phone) {
    String formatted = formatPhoneNumber(phone);
    return RegExp(r'^\+9639[0-9]{8}$').hasMatch(formatted);
  }

  // التحقق من نوع الإدخال (بريد إلكتروني أم رقم هاتف)
  static bool isEmail(String input) {
    return input.contains('@');
  }

  // تنسيق رقم الهاتف
  static String formatPhoneNumber(String phone) {
    // إزالة جميع الأحرف غير الرقمية
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // إزالة الصفر من البداية إن وجد
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    // إضافة رمز البلد إذا لم يكن موجوداً
    if (!phone.startsWith('963')) {
      phone = '963$phone';
    }
    return '+$phone';
  }

  // تحويل الجنس من عربي إلى إنجليزي
  static String _convertGenderToEnglish(String gender) {
    gender = gender.toLowerCase().trim();
    if (gender == 'ذكر' || gender == 'male') {
      return 'male';
    } else if (gender == 'أنثى' || gender == 'female') {
      return 'female';
    }
    return '';
  }

  // تحويل الجنس من إنجليزي إلى عربي
  static String convertGenderToArabic(String gender) {
    gender = gender.toLowerCase().trim();
    if (gender == 'male' || gender == 'ذكر') {
      return 'ذكر';
    } else if (gender == 'female' || gender == 'أنثى') {
      return 'أنثى';
    }
    return '';
  }

  // رفع صورة غلاف للإعلان المميز
  //  تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> uploadVipCoverImage({
    required String imagePath,
    required String fileName,
  }) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};

      // 1. استخدام MultipartRequest بدلاً من http.post
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vip-ads/upload-cover'),
      );

      request.headers.addAll(getHeaders(token));

      // 2. إضافة الحقول النصية
      request.fields['file_name'] = fileName;

      // 3. إضافة الملف الحقيقي من مساره
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // اسم حقل الملف الذي يتوقعه الخادم
          imagePath,
        ),
      );

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, 'uploadVipCoverImage');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // رفع ملف وسائط للإعلان المميز
  //  تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> uploadVipMediaFile({
    required String filePath,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final token = await getToken();
      if (token == null)
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};

      // 1. استخدام MultipartRequest
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/vip-ads/uploadMediaFile'),
      );

      request.headers.addAll(getHeaders(token));

      // 2. إضافة الحقول النصية
      request.fields['file_name'] = fileName;
      request.fields['file_type'] = fileType;

      // 3. إضافة الملف الحقيقي من مساره (اسم الحقل هنا 'file')
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, 'uploadVipMediaFile');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // إنشاء إعلان مميز محسن
  //  تم التعديل: تغيير الرابط والطريقة لتتوافق مع Postman
  static Future<Map<String, dynamic>> createEnhancedVipAd({
    required String title,
    String? description,
    required String coverImageUrl,
    List<String> mediaUrls = const [],
    String? contactPhone,
    String? contactWhatsapp,
    double? pricePaid,
    String? currency,
    int? durationHours,
    String status = 'active',
  }) async {
    try {
      final token = await getToken();
      //  تم التعديل: تغيير الرابط إلى /api/vip-ads/createEnhancedVipAd
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/vip-ads/createEnhancedVipAd'),
            headers: {
              ...getHeaders(token),
              'Content-Type':
                  'application/json; charset=utf-8', //  تم الإضافة: لأن الطلب raw json
            },
            body: json.encode({
              'title': title,
              'description': description,
              'cover_image_url': coverImageUrl,
              'media_files': mediaUrls,
              'contact_phone': contactPhone,
              'contact_whatsapp': contactWhatsapp,
              'price_paid': pricePaid,
              'currency': currency,
              'duration_hours': durationHours,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'createEnhancedVipAd');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب الإعلانات المميزة للعرض العام
  static Future<Map<String, dynamic>> getVipAdsForDisplay() async {
    try {
      print('📤 جلب إعلانات VIP للعرض العام...');
      final response = await http
          .get(Uri.parse('$baseUrl/api/vip-ads/public'))
          .timeout(const Duration(seconds: 30));

      print('📥 استجابة إعلانات VIP: Status ${response.statusCode}');
      print('📥 محتوى الاستجابة: ${response.body}');

      final result = _handleResponse(response, 'get_vip_ads_public');

      if (result['success'] == true) {
        //  التأكد من تنسيق البيانات
        final ads = result['data'] ?? result['ads'] ?? [];

        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب الإعلانات المميزة بنجاح',
          'data': List<Map<String, dynamic>>.from(ads),
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // استدعاء ملف المستخدم ومنشوراته
  static Future<Map<String, dynamic>> getUserProfileAndPosts(int userId) async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/user/profile-and-posts?id=$userId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_user_profile_and_posts');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // دالة البحث
  static Future<Map<String, dynamic>> search(String query) async {
    try {
      if (query.trim().isEmpty) {
        return {'success': false, 'message': 'كلمة البحث مطلوبة'};
      }

      final token = await getToken();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/search?query=${Uri.encodeComponent(query)}',
            ),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'search');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دوال المراسلة ========

  // جلب المحادثات
  static Future<Map<String, dynamic>> getConversations() async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/conversations'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_conversations');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب الرسائل
  static Future<Map<String, dynamic>> getMessages(
    int conversationId,
    int page,
  ) async {
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/get/messages?conversation_id=$conversationId',
            ),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'get_messages');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // إرسال رسالة
  static Future<Map<String, dynamic>> sendMessage(
    int receiverId,
    String content,
  ) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/send/messages'),
        headers: {...getHeaders(token)},
        body: {'receiver_id': receiverId.toString(), 'content': content},
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'send_message');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دوال الإشعارات ========

  // جلب الإشعارات
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/notifications?page=$page&limit=$limit'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      // معالجة خاصة للإشعارات مع دعم Firebase
      final result = _handleResponse(response, 'getNotifications');

      // إذا كان هناك خطأ 404، قم بإرجاع بيانات فارغة بدلاً من الخطأ
      if (response.statusCode == 404) {
        return {
          'success': true,
          'data': {
            'notifications': [],
            'unread_count': 0,
            'total': 0,
            'current_page': page,
          },
          'message': 'لا توجد إشعارات متاحة حالياً',
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // تعليم الإشعارات كمقروءة
  static Future<Map<String, dynamic>> markNotificationsAsRead({
    List<int>? notificationIds,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final requestData = <String, dynamic>{};
      if (notificationIds != null) {
        requestData['notification_ids'] = notificationIds;
      }

      //  تم التعديل: افتراض رابط تعليم كمقروء
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notifications/mark-as-read'),
            headers: getHeaders(token),
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'markNotificationsAsRead');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دوال التقارير/الإبلاغات ========

  // الإبلاغ عن منشور
  static Future<Map<String, dynamic>> reportPost({
    required int postId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final Map<String, String> requestData = {
        'post_id': postId.toString(),
        'reason': reason,
        'description': description ?? '',
      };
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/posts/report'),
            headers: {...getHeaders(token)},
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'reportPost');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب تقارير المنشورات (للأدمن)
  static Future<Map<String, dynamic>> getPostReports() async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/show/reports/posts'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'getPostReports');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // تحديث حالة التقرير
  static Future<Map<String, dynamic>> updateReportStatus({
    required int reportId,
    required String status,
    String? adminResponse,
  }) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }
    try {
      final token = await getToken();
      final Map<String, String> requestData = {
        'report_id': reportId.toString(),
        'status': status,
        'admin_response': adminResponse ?? '',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/reports/update-status'),
            headers: {...getHeaders(token)},
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'updateReportStatus');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // الإبلاغ عن تعليق
  static Future<Map<String, dynamic>> reportComment({
    required int commentId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final requestData = {
        'comment_id': commentId,
        'reason': reason,
        'description': description ?? '',
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/comments/report'),
            headers: getHeaders(token),
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'reportComment');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // جلب المنشورات حسب الفئة
  static Future<Map<String, dynamic>> getPostsByCategory(
    String categoryName, {
    int page = 1,
  }) async {
    try {
      final token = await getToken();

      // 🔍 البحث عن الـ ID المناسب للاسم
      int? categoryId = _findCategoryIdByName(categoryName);

      if (categoryId == null) {
        return {'success': false, 'message': 'القسم غير موجود: $categoryName'};
      }

      final uri = Uri.parse('$baseUrl/api/posts').replace(
        queryParameters: {
          'category_id': categoryId.toString(), //  استخدام category_id
          'page': page.toString(),
        },
      );

      final response = await http.get(uri, headers: getHeaders(token));
      return _handleResponse(response, 'get_posts_by_category');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // دالة مساعدة للعثور على ID القسم حسب الاسم
  static int? _findCategoryIdByName(String categoryName) {
    final categoryMap = {
      'التوظيف': 13,
      'المناقصات': 14,
      'الموردين': 15,
      'العروض العامة': 16,
      'السيارات': 1,
      'الدراجات النارية': 2,
      'تجارة العقارات': 3,
      'المستلزمات العسكرية': 4,
      'الهواتف والالكترونيات': 5,
      'الأدوات الكهربائية': 6,
      'ايجار العقارات': 7,
      'الثمار والحبوب': 8,
      'المواد الغذائية': 9,
      'المطاعم': 10,
      'مواد التدفئة': 11,
      'المكياج و الاكسسوار': 12,
      'المواشي والحيوانات': 17,
      'الكتب و القرطاسية': 18,
      'الأدوات المنزلية': 19,
      'الملابس والأحذية': 20,
      'أثاث المنزل': 21,
      'تجار الجملة': 22,
      'الموزعين': 23,
      'أسواق أخرى': 24,
    };

    return categoryMap[categoryName];
  }

  static Future<Map<String, dynamic>> togglePostLike(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 تبديل الإعجاب للمنشور ID: $postId');

      // إرسال طلب تبديل الإعجاب
      final uri = Uri.parse('$baseUrl/api/toggleLike?post_id=$postId');
      final response = await http
          .get(uri, headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'toggle_post_like');

      print('📥 استجابة تبديل الإعجاب: ${result}');

      if (result['success'] == true) {
        //  إرجاع البيانات المحدثة من الخادم
        return {
          'success': true,
          'message': result['message'] ?? 'تم تحديث الإعجاب بنجاح',
          'isLiked': result['isLiked'] ?? false, // الحالة الجديدة للإعجاب
          'likesCount': result['likesCount'] ??
              result['likes_count'] ??
              0, // العدد المحدث
          'data': result['data'], // بيانات إضافية إن وجدت
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دالة جديدة لجلب إحصائيات المنشور فقط (للتحديث الدوري) ========
  static Future<Map<String, dynamic>> getPostStats(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📊 جلب إحصائيات المنشور ID: $postId');

      // يمكنك استخدام endpoint محدد للإحصائيات أو جلب المنشور كاملاً
      // هنا نستخدم endpoint بسيط يجلب فقط الإحصائيات
      final uri = Uri.parse('$baseUrl/api/posts/$postId/stats');
      final response = await http
          .get(uri, headers: getHeaders(token))
          .timeout(const Duration(seconds: 15));

      final result = _handleResponse(response, 'get_post_stats');

      if (result['success'] == true) {
        return {
          'success': true,
          'likes_count':
              result['likes_count'] ?? result['data']?['likes_count'] ?? 0,
          'comments_count': result['comments_count'] ??
              result['data']?['comments_count'] ??
              0,
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  static Future<Map<String, dynamic>> addComment({
    required int postId,
    required String content,
    int? parentCommentId, // معرف التعليق الأصلي للرد عليه
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 إضافة تعليق للمنشور ID: $postId');

      final Map<String, String> requestData = {
        'post_id': postId.toString(),
        'content': content,
      };

      // إضافة parent_comment_id فقط إذا تم توفيره (للردود)
      if (parentCommentId != null) {
        requestData['parent_comment_id'] = parentCommentId.toString();
      }

      // إرسال الطلب
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/comments/add'),
            headers: {...getHeaders(token)},
            body: requestData,
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'add_comment');

      print('📥 استجابة إضافة التعليق: ${result}');

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'تم إضافة التعليق بنجاح',
          'comment': result['comment'] ?? result['data'], // التعليق الجديد
          'comments_count': result['comments_count'] ??
              result['total_comments'], // العدد المحدث
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ======== دالة جلب تعليقات منشور ========
  static Future<Map<String, dynamic>> getComments(int postId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      print('📤 جلب التعليقات للمنشور ID: $postId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/comments?post_id=$postId'),
            headers: getHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'get_comments');

      print('📥 استجابة جلب التعليقات: ${result}');

      if (result['success'] == true) {
        //  التأكد من وجود مفتاح التعليقات في الاستجابة
        final comments = result['comments'] ?? result['data'] ?? [];

        return {
          'success': true,
          'message': result['message'] ?? 'تم جلب التعليقات بنجاح',
          'comments': List<Map<String, dynamic>>.from(comments),
          'total_comments': result['total_comments'] ??
              result['comments_count'] ??
              comments.length,
        };
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  static Future<Map<String, dynamic>> toggleCommentLike(int commentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/comments/toggle-like'),
        headers: {...getHeaders(token)},
        body: {
          'comment_id': commentId.toString(),
        },
      ).timeout(const Duration(seconds: 30));

      return _handleResponse(response, 'toggle_comment_like');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  static Future<String?> _getToken() async {
    return _userToken;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
    } else {
      return {'Accept': 'application/json'};
    }
  }

  // دالة جديدة لجلب المنشورات حسب category_id
  static Future<Map<String, dynamic>> getPostsByCategoryId(
    int categoryId, {
    int page = 1,
  }) async {
    try {
      final token = await getToken();

      print('📤 جلب المنشورات للقسم ID: $categoryId, الصفحة: $page');

      //  استخدام الرابط الجديد مع category_id
      final uri = Uri.parse('$baseUrl/api/categories/$categoryId?page=$page');

      final response = await http
          .get(uri, headers: getHeaders(token))
          .timeout(const Duration(seconds: 30));

      print('📥 استجابة جلب المنشورات: Status ${response.statusCode}');

      return _handleResponse(response, 'get_posts_by_category_id');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // إرسال إشعار لجميع المستخدمين (للأدمن فقط)
  static Future<Map<String, dynamic>> sendNotificationToAll({
    required String title,
    required String body,
  }) async {
    if (!checkAdminPermissions()) {
      return {'success': false, 'message': 'ليس لديك صلاحيات إدارية'};
    }

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'المستخدم غير مسجل الدخول'};
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notifications/sendtoall'),
            headers: {...getHeaders(token), 'Content-Type': 'application/json'},
            body: json.encode({'title': title, 'body': body}),
          )
          .timeout(const Duration(seconds: 60));

      return _handleResponse(response, 'sendNotificationToAll');
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }

  // ⭐ دالة جديدة لجلب منشور محدد حسب الرقم التعريفي
  // في ملف auth_service.dart، استبدل الدالة القديمة بهذه الدالة المعدلة

  static Future<Map<String, dynamic>> getPostById(int postId) async {
    try {
      // 1. استخدام الدالة العامة getHeaders() لجلب التوكن بشكل صحيح
      final token = await getToken();

      // 2. بناء الرابط الصحيح مع إضافة /api
      final uri = Uri.parse('$baseUrl/api/posts/$postId');

      print('📤 جلب منشور واحد من: $uri'); // للتصحيح

      final response = await http
          .get(uri, headers: getHeaders(token)) // استخدام getHeaders العامة
          .timeout(const Duration(seconds: 30));

      final result = _handleResponse(response, 'get_post_by_id');

      // 3. تحليل الاستجابة الصحيحة
      if (result['success'] == true) {
        // الباك إند يعيد البيانات في مفتاح 'data'
        final postData = result['data'];
        if (postData != null) {
          return {
            'success': true,
            'post':
                postData, // وضع البيانات تحت مفتاح 'post' كما يتوقع Frontend
          };
        } else {
          return {'success': false, 'message': 'بيانات المنشور فارغة'};
        }
      }

      return result;
    } catch (e) {
      // طباعة الخطأ الحقيقي للمطور في الـ Console
      print('⚠️ خطأ تقني في [اسم الدالة هنا]: $e');

      String userMessage =
          'حدث خطأ في الاتصال بالانترنت، يرجى المحاولة مرة أخرى.';

      // تحديد نوع الخطأ بناءً على نص الاستثناء
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('socketexception') ||
          errorString.contains('connection refused')) {
        userMessage =
            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'استغرق الأمر وقتًا طويلاً، يرجى المحاولة مرة أخرى.';
      } else if (errorString.contains('failed to fetch')) {
        userMessage = 'فشل الاتصال بالخادم، يرجى المحاولة لاحقًا.';
      }

      return {
        'success': false,
        'message': userMessage, // رسالة واضحة ومناسبة للمستخدم
      };
    }
  }
}
