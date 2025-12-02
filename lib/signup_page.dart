import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'auth_service.dart';
import 'privacy_policy_page.dart';
import 'email_verification_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreeToPrivacyPolicy = false;
  bool _passwordsMatch = true;
  bool _isLoading = false;
  String _selectedGender = 'ذكر';
  String _selectedUserType = 'person'; // 'person' or 'store'
  bool _addPhoneNumber = false;

  // قائمة الدول مع الأيموجيز الحقيقية للأعلام
  final List<Map<String, dynamic>> _countries = [
    {'name': 'سوريا', 'code': '+963'},
    {'name': 'لبنان', 'code': '+961'},
    {'name': 'الأردن', 'code': '+962'},
    {'name': 'الإمارات', 'code': '+971'},
    {'name': 'السعودية', 'code': '+966'},
    {'name': 'مصر', 'code': '+20'},
    {'name': 'تركيا', 'code': '+90'},
    {'name': 'فلسطين', 'code': '+972'},
    {'name': 'العراق', 'code': '+964'},
    {'name': 'ليبيا', 'code': '+218'},
    {'name': 'تونس', 'code': '+216'},
    {'name': 'الجزائر', 'code': '+213'},
    {'name': 'السودان', 'code': '+249'},
    {'name': 'الصومال', 'code': '+252'},
    {'name': 'اليمن', 'code': '+967'},
    {'name': 'الكويت', 'code': '+965'},
    {'name': 'قطر', 'code': '+974'},
    {'name': 'البحرين', 'code': '+973'},
    {'name': 'المغرب', 'code': '+212'},
  ];

  late Map<String, dynamic> _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.firstWhere(
      (country) => country['code'] == '+963',
      orElse: () => _countries[0],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
        email: _emailController.text.trim(),
        password: _passwordController.text,
        gender: _selectedGender,
        phone: _addPhoneNumber ? _phoneController.text.trim() : null,
        userType: _selectedUserType,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await AuthService.loadUserData();

        // التحقق مما إذا كان التسجيل يتطلب تأكيد البريد الإلكتروني
        if (result['email_verification_required'] == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => const EmailVerificationPage()),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        String errorMessage = 'فشل إنشاء الحساب، حاول مرة أخرى لاحقاً.';

        // تحقق مما إذا كانت الاستجابة تحتوي على أخطاء تحقق (Validation Errors)
        if (result.containsKey('errors') && result['errors'] is Map) {
          final errors = Map<String, dynamic>.from(result['errors']);

          // ابحث عن خطأ متعلق بالإيميل أو رقم الهاتف
          if (errors.containsKey('email_or_phone')) {
            errorMessage = 'هذا البريد الإلكتروني أو رقم الهاتف مستخدم بالفعل.';
          } else if (errors.containsKey('email')) {
            errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل.';
          } else if (errors.containsKey('phone')) {
            errorMessage = 'رقم الهاتف مستخدم بالفعل.';
          } else {
            // إذا كان هناك خطأ آخر، اعرض أول رسالة خطأ تجدها
            if (errors.isNotEmpty) {
              final firstErrorKey = errors.keys.first;
              final firstErrorMessages = errors[firstErrorKey];
              if (firstErrorMessages is List && firstErrorMessages.isNotEmpty) {
                errorMessage = firstErrorMessages.first.toString();
              }
            }
          }
        } else if (result.containsKey('message')) {
          // إذا لم تكن هناك أخطاء تحقق، استخدم الرسالة العامة
          errorMessage = result['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع.'),
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
            child: Column(children: [
              const SizedBox(height: 20),
              Text(
                'Minex',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'بيع وشراء بكل سهولة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
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

              // حقل البريد الإلكتروني (إلزامي دائماً)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني (إلزامي)',
                  labelStyle: TextStyle(color: _primaryColor),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _primaryColor, width: 2)),
                  prefixIcon: Icon(Icons.email, color: _primaryColor),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال البريد الإلكتروني';
                  if (!AuthService.isValidEmail(value))
                    return 'الرجاء إدخال بريد إلكتروني صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Checkbox لإضافة رقم الهاتف
              CheckboxListTile(
                title: const Text('إضافة رقم هاتف (اختياري)'),
                value: _addPhoneNumber,
                onChanged: (bool? value) {
                  setState(() {
                    _addPhoneNumber = value!;
                  });
                },
                activeColor: _primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              // حقول الهاتف تظهر فقط عند تحديد الـ Checkbox
              if (_addPhoneNumber) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9)
                        ],
                        decoration: InputDecoration(
                          labelText: 'رقم الهاتف',
                          labelStyle: TextStyle(color: _primaryColor),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: _primaryColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: _primaryColor, width: 2)),
                          prefixIcon: Icon(Icons.phone, color: _primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'رمز الدولة',
                          labelStyle: TextStyle(color: _primaryColor),
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: _primaryColor)),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: _primaryColor, width: 2)),
                        ),
                        items: _countries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Row(children: [
                              Text(country['name'],
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('${country['code']}')
                            ]),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCountry = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

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

              // اختيار نوع الحساب (بنفس تصميم اختيار الجنس)
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
              const SizedBox(height: 10),

              // إضافة عبارة التحذير هنا
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber[800]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تنبيه: احفظ بريدك وكلمة مرورك، فسوف تحتاجهم في الصفحة التالية.',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // إضافة عبارة حول تأكيد البريد الإلكتروني
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سيتم إرسال بريد تأكيد إلى بريدك الإلكتروني بعد التسجيل',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
            ]),
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
