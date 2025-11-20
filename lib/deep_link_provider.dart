import 'package:flutter/foundation.dart';

class DeepLinkProvider with ChangeNotifier {
  int? _pendingPostId;

  int? get pendingPostId => _pendingPostId;

  void setPendingPostId(int? id) {
    _pendingPostId = id;
    notifyListeners(); // إبلاغ المستهلكين بتغيير القيمة
  }

  void clearPendingPostId() {
    _pendingPostId = null;
    notifyListeners();
  }
}
