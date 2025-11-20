import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'signup_page.dart';
// ملفات المشروع
import 'firebase_options.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'firebase_api.dart';

// مفتاح عام للتنقل
import 'app_globals.dart';

// من اجل الروابط العميقة
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart'; // ⭐ استيراد provider
import 'deep_link_provider.dart'; // ⭐ استيراد مزود الرابط العميق
import 'search_page.dart'; // ⭐ لاستخدام SearchPage في _navigateToSearchWithPostContent

// ⭐ نقل الدالتين إلى مستوى خارج أي ودجت
// ⭐ دالة لفتح صفحة البحث مع محتوى المنشور
Future<void> _navigateToSearchWithPostContent(
  BuildContext context,
  int postId,
  Function(String query) onSearchRequested,
) async {
  print('جاري جلب محتوى المنشور $postId...');
  try {
    final result = await AuthService.getPostById(
        postId); // ⭐ استخدام دالة موجودة في AuthService لجلب منشور محدد
    if (result['success'] == true && result['post'] != null) {
      Map<String, dynamic> post = result['post'];
      // ⭐ استخدم محتوى أو عنوان المنشور ككلمة بحث
      String searchQuery = post['content'] ?? post['title'] ?? '';

      if (searchQuery.isNotEmpty) {
        print('تم جلب محتوى المنشور. البحث عن: "$searchQuery"');
        // ⭐ التنقل إلى صفحة البحث
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(initialQuery: searchQuery), // ⭐ تمرير كلمة البحث
          ),
        );
      } else {
        print(
            'لم يتم العثور على محتوى أو عنوان للمنشور $postId لاستخدامه في البحث.');
        // يمكن عرض رسالة للمستخدم هنا
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('لم يتم العثور على محتوى المنشور $postId')),
          );
        }
      }
    } else {
      print('فشل جلب المنشور $postId: ${result['message']}');
      // يمكن عرض رسالة للمستخدم هنا
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في العثور على المنشور $postId')),
        );
      }
    }
  } catch (e) {
    print('خطأ أثناء جلب المنشور $postId: $e');
    // يمكن عرض رسالة للمستخدم هنا
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء جلب المنشور $postId')),
      );
    }
  }
}

void initDeepLinks(BuildContext context) async {
  // ⭐ إضافة BuildContext
  final appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) async {
    // ⭐ جعل الاستماع غير متزامن
    // ignore: unnecessary_null_comparison
    if (uri != null) {
      print('تم استقبال الرابط: $uri');
      if (uri.host == 'kiniru.site' || uri.host == 'www.kiniru.site') {
        String path = uri.path;
        List<String> segments =
            path.split('/').where((s) => s.isNotEmpty).toList();

        if (segments.isNotEmpty &&
            segments[0] == 'post' &&
            segments.length > 1) {
          String postIdString = segments[1];
          int? postId = int.tryParse(postIdString);

          if (postId != null) {
            print('الرقم التعريفي للمنشور: $postId');
            // ⭐ استدعاء الدالة الجديدة مع السياق
            await _navigateToSearchWithPostContent(context, postId, (query) {
              // هذه الدالة فارغة الآن، لكن يمكن استخدامها لاحقًا إذا احتجت لاست callable من main
              // في حالتنا، SearchPage ستعمل البحث بمجرد بدء التشغيل
            });
            return;
          }
        }
      }
      print('الرابط غير معتمد أو لا يمكن معالجته: $uri');
    }
  }).onError((error) {
    print('خطأ في استقبال الرابط: $error');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    debugPrint(' Firebase initialized');
  } catch (e, st) {
    debugPrint('⚠️ Firebase.initializeApp failed or timed out: $e');
    debugPrint('$st');
  }

  try {
    await AuthService.loadUserData().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint("⚠️ loadUserData error: $e");
  }

  runZonedGuarded(
    () {
      runApp(
        // ⭐ ⭐ ⭐ تم لف MyApp بكلاس ChangeNotifierProvider ⭐ ⭐ ⭐
        ChangeNotifierProvider(
          create: (context) =>
              DeepLinkProvider(), // ⭐ إنشاء مثيل من DeepLinkProvider
          child: MyApp(), // ⭐ MyApp هو الولد (child) لهذا المزود
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error (zone): $error');
      debugPrint('$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minex',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      routes: {'/notifications': (context) => const NotificationsPage()},
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // بعد ال frame الأولي نقوم بالتنقل والتحقق ونشغّل الإشعارات (غير محظور)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ⭐ ⭐ ⭐ استدعاء initDeepLinks هنا ⭐ ⭐ ⭐
      // لضمان وجود BuildContext وبدء الاستماع فورًا بعد أن تكون الواجهة جاهزة
      initDeepLinks(context);

      // تشغيل الإشعارات بدون حظر واجهة المستخدم
      FirebaseApi().initNotifications().catchError((e) {
        debugPrint("⚠️ initNotifications failed: $e");
      });

      _navigateBasedOnAuthStatus();
    });
  }

  void _navigateBasedOnAuthStatus() async {
    await AuthService.loadUserData();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (AuthService.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Minex',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'بيع وشراء بكل سهولة',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  // ⭐ ⭐ ⭐ الدالتين _navigateToSearchWithPostContent و initDeepLinks تم نقلهما إلى الأعلى ⭐ ⭐ ⭐
  // وبالتالي لم تعدا مطلوبتين هنا.
}
