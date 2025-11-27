import 'dart:async';
import 'package:flutter/material.dart';
// تم إزالة استيرادات Firebase
import 'signup_page.dart';
// ملفات المشروع
import 'auth_service.dart';
import 'home_page.dart';
import 'notifications_page.dart';
// تم إزالة استيراد Firebase API

// مفتاح عام للتنقل
import 'app_globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // تم إزالة تهيئة Firebase تماماً

  debugPrint('✅ التطبيق يعمل بدون Firebase');

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

    // بعد ال frame الأولي نقوم بالتنقل والتحقق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تم إزالة استدعاء الإشعارات المرتبطة بـ Firebase
      debugPrint("🔕 الإشعارات معطلة مؤقتاً");

      _navigateBasedOnAuthStatus();
    });
  }

  void _navigateBasedOnAuthStatus() async {
    await AuthService.loadUserData();
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // استخدام بيانات وهمية للاختبار
    bool isLoggedIn = false; // يمكن تغييرها لاختبار مختلف التدفقات

    if (isLoggedIn) {
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
            const SizedBox(height: 30),
            // إضافة مؤشر أن التطبيق يعمل بدون Firebase
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'وضع الاختبار - بدون Firebase',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
