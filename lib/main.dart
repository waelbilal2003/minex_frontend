import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'email_link_handler_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // معالجة الروابط الواردة من البريد الإلكتروني
      onGenerateRoute: (settings) {
        // التحقق من الروابط التي تحتوي على معلمات التحقق
        if (settings.name != null && settings.name!.contains('verify-email')) {
          final uri = Uri.parse(settings.name!);
          return MaterialPageRoute(
            builder: (context) => EmailLinkHandlerPage(
              emailLink: uri.toString(),
            ),
          );
        }
        
        // الصفحة الافتراضية
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
      home: const LoginPage(),
    );
  }
}


