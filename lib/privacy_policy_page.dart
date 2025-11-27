import 'package:flutter/material.dart';

// تم حذف جميع الاستيرادات غير الضرورية
// لم نعد بحاجة لـ WillPopScope أو AuthService أو أي صفحات أخرى

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // لقد قمنا بإزالة WillPopScope completely
    // و AppBar سيعود للسلوك الافتراضي
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        // تم إزالة الـ leading المخصص وسيعود السهم الافتراضي
        // والضغط عليه سيقوم بـ Navigator.pop() تلقائياً
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('مقدمة'),
            _buildParagraph(
                'نشكرك على استخدامك تطبيقنا Minex. نولي أهمية كبيرة لخصوصية عملائنا ونسعى لحماية بياناتهم الشخصية. تهدف سياسة الخصوصية هذه إلى توضيح كيفية جمعنا للمعلومات الشخصية واستخدامها وحمايتها عندما تستخدم تطبيقنا. باستخدامك لتطبيقنا، فإنك توافق على شروط سياسة الخصوصية هذه.'),
            const SizedBox(height: 16),
            _buildSectionTitle('1. المعلومات التي نقوم بجمعها'),
            _buildParagraph(
                'عند استخدام تطبيقنا، قد نقوم بجمع المعلومات التالية:'),
            _buildBulletPoint(
                'المعلومات الشخصية: مثل الاسم، البريد الإلكتروني، رقم الهاتف.'),
            _buildBulletPoint(
                'سجل التصفح: مثل الصفحات التي زرتها داخل التطبيق، والمنتجات التي نظرت إليها أو تفاعلت معها.'),
            const SizedBox(height: 16),
            _buildSectionTitle('2. كيفية استخدامنا للمعلومات'),
            _buildParagraph(
                'نستخدم المعلومات التي نجمعها منك للأغراض التالية:'),
            _buildBulletPoint(
                'توفير الخدمات: لمعالجة طلباتك، وتقديم الدعم الفني، وإرسال إشعارات حول طلباتك.'),
            _buildBulletPoint(
                'تحسين التطبيق: لتحليل سلوك المستخدمين وتحسين تجربة المستخدم.'),
            _buildBulletPoint(
                'التسويق والإعلانات: لإرسال عروض ترويجية، وتحديثات حول المنتجات والخدمات.'),
            _buildBulletPoint(
                'حماية الأمان: لمنع الأنشطة الاحتيالية أو غير القانونية، وحماية حقوق الملكية الفكرية.'),
            const SizedBox(height: 16),
            _buildSectionTitle('3. حماية البيانات'),
            _buildParagraph(
                'نحن نتخذ إجراءات أمان مناسبة لحماية بياناتك الشخصية من الوصول غير المصرح به أو التلاعب أو الفقدان. ومع ذلك، لا يمكن ضمان الأمن الكامل للبيانات عبر الإنترنت.'),
            const SizedBox(height: 16),
            _buildSectionTitle('4. حقوقك'),
            _buildParagraph('لديك الحقوق التالية فيما يتعلق ببياناتك الشخصية:'),
            _buildBulletPoint(
                'الوصول إلى بياناتك: يمكنك الوصول إلى بياناتك الشخصية التي نحتفظ بها.'),
            _buildBulletPoint(
                'تصحيح البيانات: يمكنك طلب تصحيح أو تحديث البيانات غير الدقيقة.'),
            _buildBulletPoint(
                'حذف البيانات: يمكنك طلب حذف بياناتك الشخصية، وفقًا للقوانين المعمول بها.'),
            const SizedBox(height: 16),
            _buildSectionTitle('5. التحديثات على سياسة الخصوصية'),
            _buildParagraph(
                'قد نقوم بتحديث سياسة الخصوصية هذه من وقت لآخر. سنخطرك بأي تغييرات جوهرية من خلال إشعار داخل التطبيق.'),
            const SizedBox(height: 16),
            _buildSectionTitle('6. الاتصال بنا'),
            _buildParagraph(
                'إذا كان لديك أي استفسارات أو مخاوف بشأن سياسة الخصوصية هذه، يمكنك التواصل معنا داخل التطبيق عن طريق رقم الشكاوى أو التواصل مع الدعم الفني.'),
            const SizedBox(height: 24),
            _buildSectionTitle('موافقتك'),
            _buildParagraph(
                'باستخدامك لتطبيقنا، فإنك توافق على شروط سياسة الخصوصية هذه. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق. شكراً لك.'),
          ],
        ),
      ),
    );
  }

  // باقي الدوال تبقى كما هي بدون أي تغيير
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
