import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'signup_page.dart';
// ملفات المشروع
import 'firebase_options.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'firebase_api.dart';

// مفتاح عام للتنقل
import 'app_globals.dart';

import 'post_details_page.dart';

// في دالة main، بعد تهيئة Firebase
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
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error (zone): $error');
      debugPrint('$stack');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<AppLink>? _linkSubscription; // 🔥 يصغي إلى AppLink
  String? _initialLink;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // 🔥 الطريقة الرسمية الصحيحة: استخدام getInitialAppLink()
    try {
      final AppLink? initialAppLink = await _appLinks.getInitialAppLink();
      if (initialAppLink != null) {
        debugPrint('Initial link: ${initialAppLink.link}');
        // نستخدم .link للحصول على Uri ثم نحوله إلى String
        _handleDeepLink(initialAppLink.link.toString());
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // 🔥 الطريقة الرسمية الصحيحة: استخدام appLinkStream
    _linkSubscription = _appLinks.appLinkStream.listen((AppLink appLink) {
      debugPrint('Received link: ${appLink.link}');
      // نحول Uri إلى String لمعالجته
      _handleDeepLink(appLink.link.toString());
    }, onError: (err) {
      debugPrint('Error listening to link stream: $err');
    });
  }

  void _handleDeepLink(String link) {
    // التحقق من أن الرابط يبدأ بـ https://minexsy.site/posts/
    if (link.startsWith('https://minexsy.site/posts/')) {
      // استخراج الـ ID من الرابط
      final postIdString = link.substring('https://minexsy.site/posts/'.length);
      final postId = int.tryParse(postIdString);

      // إذا كان الـ ID صحيحاً، انتقل إلى صفحة التفاصيل
      if (postId != null) {
        // حفظ الرابط لاستخدامه لاحقاً بعد بناء الواجهة
        setState(() {
          _initialLink = link;
        });
      }
    }
  }

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
      home: SplashScreen(initialLink: _initialLink),
      routes: {'/notifications': (context) => const NotificationsPage()},
      // إضافة onGenerateRoute للتعامل مع الروابط الديناميكية
      onGenerateRoute: (settings) {
        // التحقق من أن المسار يبدأ بـ /posts/
        if (settings.name?.startsWith('/posts/') == true) {
          // استخراج الـ ID من المسار
          final postIdString = settings.name?.substring('/posts/'.length);
          final postId = int.tryParse(postIdString ?? '');

          // إذا كان الـ ID صحيحاً، انتقل إلى صفحة التفاصيل
          if (postId != null) {
            return MaterialPageRoute(
              builder: (context) => PostDetailsPage(postId: postId),
            );
          }
        }

        // إذا لم يكن المسار متطابقاً، استخدم المسار الافتراضي
        return null;
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final String? initialLink;

  const SplashScreen({Key? key, this.initialLink}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // بعد ال frame الأولي نقوم بالتنقل والتحقق ونشغّل الإشعارات (غير محظور)
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    // التحقق من وجود رابط أولي
    if (widget.initialLink != null) {
      final link = widget.initialLink!;
      if (link.startsWith('https://minexsy.site/posts/')) {
        final postIdString =
            link.substring('https://minexsy.site/posts/'.length);
        final postId = int.tryParse(postIdString);

        if (postId != null) {
          // الانتقال إلى صفحة تفاصيل المنشور
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PostDetailsPage(postId: postId)),
          );
          return;
        }
      }
    }

    // الانتقال العادي حسب حالة تسجيل الدخول
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
}
