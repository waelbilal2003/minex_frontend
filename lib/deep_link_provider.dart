// في ملف deep_link_provider.dart، أضف هذه التعديلات

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'post_details_page.dart';

class DeepLinkProvider with ChangeNotifier {
  int? _pendingPostId;
  bool _hasBeenHandled = false;

  int? get pendingPostId => _pendingPostId;
  bool get hasBeenHandled => _hasBeenHandled;

  void setPendingPostId(int? id) {
    _pendingPostId = id;
    _hasBeenHandled = false;
    notifyListeners(); // إبلاغ المستهلكين بتغيير القيمة
  }

  void markAsHandled() {
    _hasBeenHandled = true;
    notifyListeners();
  }

  void clearPendingPostId() {
    _pendingPostId = null;
    _hasBeenHandled = false;
    notifyListeners();
  }

  // دالة جديدة للتعامل مع الروابط الخارجية
  static void handleDeepLink(BuildContext context, String link) {
    // التحقق من أن الرابط يبدأ بـ https://minexsy.site/posts/
    if (link.startsWith('https://minexsy.site/posts/')) {
      // استخراج الـ ID من الرابط
      final postIdString = link.substring('https://minexsy.site/posts/'.length);
      final postId = int.tryParse(postIdString);

      // إذا كان الـ ID صحيحاً، انتقل إلى صفحة التفاصيل
      if (postId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(postId: postId),
          ),
        );
      }
    }
  }
}
