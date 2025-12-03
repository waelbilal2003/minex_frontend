import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'auth_service.dart';
import 'privacy_policy_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToPrivacyPolicy = false;
  bool _passwordsMatch = true;
  bool _isLoading = false;
  String _selectedGender = 'ذكر';
  String _selectedUserType = 'person'; // 'person' or 'store'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Color get _primaryColor =>
      _selectedGender == 'ذكر' ? Colors.blue : Colors.pink;

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch =
          _passwordController.text == _confirmPasswordController.text;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!AuthService.isValidEmail(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح (مثال: user@example.com)';
    }
    return null;
  }

  Future<void> _submitForm() async {
    _checkPasswordsMatch();
    if (!_formKey.currentState!.validate() ||
        !_passwordsMatch ||
        !_agreeToPrivacyPolicy) {
      if (!_agreeToPrivacyPolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب الموافقة على سياسة الخصوصية لإنشاء حساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.register(
        fullName: _nameController.text.trim(),
        emailOrPhone: _emailController.text.trim(),
        password: _passwordController.text,
        gender: _selectedGender,
        userType: _selectedUserType,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 تم التسجيل بنجاح'),
            content: const Text(
                'تم إرسال رابط تفعيل إلى بريدك الإلكتروني. الرجاء الضغط على الرابط لتفعيل حسابك قبل تسجيل الدخول.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('حسناً، فهمت'),
              ),
            ],
          ),
        );
      } else {
        String errorMessage =
            result['message'] ?? 'فشل إنشاء الحساب، حاول مرة أخرى لاحقاً.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء حساب', style: TextStyle(color: _primaryColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // لمحاذاة العناوين
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Minex',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Text(
                    'بيع وشراء بكل سهولة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // اسم المستخدم
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.person, color: _primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // حقل البريد الإلكتروني (إلزامي)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.email, color: _primaryColor),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),

                // اختيار الجنس
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'ذكر',
                            groupValue: _selectedGender,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                          Text('ذكر', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'أنثى',
                            groupValue: _selectedGender,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                          Text('أنثى', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- بداية التصميم الجديد لنوع الحساب ---
                const Text(
                  'نوع الحساب',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: 'person',
                            groupValue: _selectedUserType,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedUserType = value!;
                              });
                            },
                          ),
                          Text('شخصي', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'store',
                            groupValue: _selectedUserType,
                            activeColor: _primaryColor,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedUserType = value!;
                              });
                            },
                          ),
                          Text('متجر', style: TextStyle(color: _primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                // --- نهاية التصميم الجديد ---
                const SizedBox(height: 20),

                // كلمة المرور
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون على الأقل 6 أحرف';
                    }
                    return null;
                  },
                  onChanged: (value) => _checkPasswordsMatch(),
                ),
                const SizedBox(height: 20),

                // تأكيد كلمة المرور
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    labelStyle: TextStyle(color: _primaryColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor),
                    errorText:
                        _passwordsMatch ? null : 'كلمات المرور غير متطابقة',
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء تأكيد كلمة المرور';
                    }
                    return null;
                  },
                  onChanged: (value) => _checkPasswordsMatch(),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToPrivacyPolicy,
                      onChanged: (value) {
                        setState(() {
                          _agreeToPrivacyPolicy = value ?? false;
                        });
                      },
                      activeColor: _primaryColor,
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'أوافق على ',
                              style: TextStyle(fontSize: 14),
                            ),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'سياسة الخصوصية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // زر إنشاء الحساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: _primaryColor,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'إنشاء حساب',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _navigateToLogin(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      'لديك حساب بالفعل؟ سجل الدخول',
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
