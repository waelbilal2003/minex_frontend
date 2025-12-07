import 'package:flutter/material.dart';
import 'firebase_email_link_service.dart';
import 'home_page.dart';

/// صفحة معالجة رابط التحقق من البريد الإلكتروني
/// 
/// هذه الصفحة يتم فتحها عند النقر على رابط التحقق في البريد الإلكتروني
class EmailLinkHandlerPage extends StatefulWidget {
  final String emailLink;
  
  const EmailLinkHandlerPage({
    Key? key,
    required this.emailLink,
  }) : super(key: key);

  @override
  State<EmailLinkHandlerPage> createState() => _EmailLinkHandlerPageState();
}

class _EmailLinkHandlerPageState extends State<EmailLinkHandlerPage> {
  final _emailController = TextEditingController();
  bool _isProcessing = true;
  bool _needsEmail = false;
  String? _errorMessage;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _processEmailLink();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// معالجة رابط البريد الإلكتروني
  Future<void> _processEmailLink() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // محاولة الحصول على البريد المحفوظ
    final savedEmail = await FirebaseEmailLinkService.getSavedEmail();
    
    setState(() {
      _savedEmail = savedEmail;
    });

    // محاولة التحقق تلقائياً إذا كان البريد محفوظاً
    if (savedEmail != null) {
      await _verifyWithEmail(savedEmail);
    } else {
      // طلب إدخال البريد يدوياً
      setState(() {
        _isProcessing = false;
        _needsEmail = true;
      });
    }
  }

  /// التحقق باستخدام البريد الإلكتروني
  Future<void> _verifyWithEmail(String email) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final result = await FirebaseEmailLinkService.signInWithEmailLink(
      emailLink: widget.emailLink,
      email: email,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // نجح التحقق - الانتقال إلى الصفحة الرئيسية
      _showSuccessDialog();
    } else {
      // فشل التحقق - عرض رسالة الخطأ
      setState(() {
        _isProcessing = false;
        _errorMessage = result['message'];
        if (result['needsEmail'] == true) {
          _needsEmail = true;
        }
      });
    }
  }

  /// عرض نافذة النجاح
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('تم التحقق بنجاح'),
          ],
        ),
        content: const Text(
          'تم التحقق من بريدك الإلكتروني بنجاح!\nسيتم نقلك إلى الصفحة الرئيسية.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق النافذة
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('متابعة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// معالجة إرسال البريد يدوياً
  void _handleManualEmailSubmit() {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال البريد الإلكتروني';
      });
      return;
    }
    
    if (!email.contains('@')) {
      setState(() {
        _errorMessage = 'يرجى إدخال بريد إلكتروني صحيح';
      });
      return;
    }
    
    _verifyWithEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من البريد الإلكتروني'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingView();
    }
    
    if (_needsEmail) {
      return _buildEmailInputView();
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    
    return const SizedBox.shrink();
  }

  /// عرض جاري المعالجة
  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'جاري التحقق من البريد الإلكتروني...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (_savedEmail != null) ...[
            const SizedBox(height: 12),
            Text(
              _savedEmail!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// عرض إدخال البريد الإلكتروني
  Widget _buildEmailInputView() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue[400],
            ),
            const SizedBox(height: 24),
            Text(
              'أدخل بريدك الإلكتروني',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يرجى إدخال البريد الإلكتروني الذي استخدمته للتسجيل',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                hintText: 'example@email.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _handleManualEmailSubmit(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleManualEmailSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'التحقق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض الخطأ
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            'حدث خطأ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _processEmailLink,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
