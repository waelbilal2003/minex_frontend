import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart'; // ✅ الإصدار الحديث
import 'signup_page.dart';

// ملفات المشروع
import 'firebase_options.dart';
import 'auth_service.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'firebase_api.dart';
import 'app_globals.dart'; // مفتاح عام للتنقل
import 'post_details_page.dart';
import 'email_link_handler_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    debugPrint('Firebase initialized');
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
  StreamSubscription<Uri?>? _linkSubscription; // ✅ تم التصحيح: Uri?
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
    try {
      // ✅ getInitialLink() يُعيد Uri?
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Initial link: $initialUri');
        _handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // ✅ uriLinkStream يُعيد Stream<Uri?>
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('Received link: $uri');
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      debugPrint('Error listening to link stream: $err');
    });
  }

  void _handleDeepLink(String link) {
    if (link.startsWith('https://minexsy.site/api/posts/')) {
      final postIdString =
          link.substring('https://minexsy.site/api/posts/'.length);
      final postId = int.tryParse(postIdString);

      if (postId != null) {
        setState(() {
          _initialLink = link;
        });
      }
    } else if (link.contains('verify-email')) {
      // ضع رابط التحقق كبداية حتى يتعامل SplashScreen معه بعد الإقلاع
      setState(() {
        _initialLink = link;
      });
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
      onGenerateRoute: (settings) {
        final name = settings.name;

        // روابط التحقق من البريد الإلكتروني (مثال: myapp://.../verify-email?token=...)
        if (name != null && name.contains('verify-email')) {
          final uri = Uri.parse(name);
          return MaterialPageRoute(
            builder: (context) => EmailLinkHandlerPage(
              emailLink: uri.toString(),
            ),
          );
        }

        // روابط فتح تفاصيل المنشور عبر المسار /api/<postId>
        if (name?.startsWith('/api/') == true) {
          final postIdString = name?.substring('/api/'.length);
          final postId = int.tryParse(postIdString ?? '');

          if (postId != null) {
            return MaterialPageRoute(
              builder: (context) => PostDetailsPage(postId: postId),
            );
          }
        }

        // افتراضيًا ارجع null لكي يستخدم `home` أو طرق معرفة أخرى
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    if (widget.initialLink != null) {
      final link = widget.initialLink!;
      // ✅ تم التصحيح هنا أيضاً
      if (link.contains('verify-email')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailLinkHandlerPage(emailLink: link),
          ),
        );
        return;
      }

      if (link.startsWith('https://minexsy.site/api/posts/')) {
        final postIdString =
            link.substring('https://minexsy.site/api/posts/'.length);
        final postId = int.tryParse(postIdString);

        if (postId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PostDetailsPage(postId: postId)),
          );
          return;
        }
      }
    }

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
            // ملاحظة: تم نقل منطق التعامل مع روابط البريد الإلكتروني إلى `MyApp.onGenerateRoute`
          ],
        ),
      ),
    );
  }
}
