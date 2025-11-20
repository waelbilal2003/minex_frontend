import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // ← ضروري لـ firstWhereOrNull
import 'auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// --- تعديل فئة MessagingDisclaimerDialog ---
// نحولها إلى واجهة شريط أفقية بسيطة تُستخدم داخل _buildDisclaimer في MessagesPage
// نحتفظ بالاسم الأصلي لكن مع تعديل الدالة build
class MessagingDisclaimerDialog extends StatefulWidget {
  final VoidCallback onAccept;
  const MessagingDisclaimerDialog({Key? key, required this.onAccept})
      : super(key: key);
  @override
  _MessagingDisclaimerDialogState createState() =>
      _MessagingDisclaimerDialogState();
}

class _MessagingDisclaimerDialogState extends State<MessagingDisclaimerDialog> {
  bool _dontShowAgain = false;
  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_messaging_disclaimer', _dontShowAgain);
  }

  @override
  Widget build(BuildContext context) {
    // هذا الكود لم يعد يستخدم كنافذة منبثقة، بل كـ Widget داخلي.
    // نحتفظ بالوظيفة الأصلية فقط لتجنب الأخطاء إذا استخدمها شخص آخر.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'ملاحظة مهمة',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "المراسلة مخصصة للدردشة المؤقتة فقط. للحصول على تجربة أفضل، اطلب من الشخص الذي تود التحدث اليه مراسلتك عبر واتساب أو تيليجرام.",
            style: TextStyle(
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                activeColor: Colors.blue,
                checkColor: Colors.white,
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() {
                    _dontShowAgain = value ?? false;
                  });
                },
              ),
              Text(
                "عدم العرض مرة أخرى",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: Size(double.infinity, 40),
            ),
            onPressed: () async {
              if (_dontShowAgain) {
                await _savePreference();
              }
              widget.onAccept();
              Navigator.of(context).pop();
            },
            child: Text(
              'موافق',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- تغييرات على فئة MessagesPage ---
class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final result = await AuthService.getConversations();
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _conversations = List<Map<String, dynamic>>.from(
              result['data'] ?? [],
            );
          });
        } else {
          setState(() {
            _error = result['message'] ?? 'فشل تحميل المحادثات';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ ما: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChatPage(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation['conversation_id'],
          otherUserId: conversation['other_user_id'],
          otherUserName: conversation['other_user_name'],
          otherUserGender: conversation['other_user_gender'],
        ),
      ),
    ).then((_) {
      _loadConversations(); // تحديث عند العودة
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      if (now.difference(date).inDays == 0) return DateFormat.Hm().format(date);
      if (now.difference(date).inDays == 1) return 'الأمس';
      return DateFormat('d/M/yy').format(date);
    } catch (e) {
      return '';
    }
  }

  // --- الدالة الجديدة لبناء شريط الإشعار ---
  Widget _buildDisclaimer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color:
          isDarkMode ? Colors.grey[850] : Colors.blue.shade50, // لون خلفية لطيف
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "المراسلة مخصصة للدردشة المؤقتة فقط. للحصول على تجربة أفضل، اطلب من الشخص الذي تود التحدث اليه مراسلتك عبر واتساب أو تيليجرام.",
              style: TextStyle(
                fontSize: 12, // حجم نص أصغر ليناسب الشريط
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center, // محاذاة النص في المنتصف
            ),
          ),
          // تم حذف IconButton هنا، لذا لا يوجد زر إغلاق
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildDisclaimer(), // <-- ضعه هنا في الأعلى
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error));
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد محادثات بعد',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          final bool isUnread = (convo['unread_count'] ?? 0) > 0;

          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: convo['other_user_gender'] == 'male'
                      ? Colors.blue.shade100
                      : Colors.pink.shade100,
                  child: Text(
                    convo['other_user_name']?.substring(0, 1) ?? 'U',
                    style: TextStyle(
                      color: convo['other_user_gender'] == 'male'
                          ? Colors.blue
                          : Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  convo['other_user_name'] ?? 'مستخدم',
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  convo['last_message_content'] ?? '...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(convo['last_message_at']),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (isUnread) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          convo['unread_count'].toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () => _openChatPage(convo),
              ),
              Divider(height: 1, indent: 80),
            ],
          );
        },
      ),
    );
  }
}

// --- فئة ChatPage بدون التغييرات السابقة ---
class ChatPage extends StatefulWidget {
  final int? conversationId;
  final int otherUserId;
  final String otherUserName;
  final String otherUserGender;
  const ChatPage({
    Key? key,
    this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserGender,
  }) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  Timer? _pollingTimer;
  String? _lastMessageId;
  // إزالة _shouldShowDisclaimer لأننا نعتمد على SharedPreferences في MessagesPage الآن

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
    // تم حذف _checkAndShowDisclaimer(); من هنا
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && !_isUserTyping) {
        _loadMessagesSilently();
      }
    });
  }

  bool get _isUserTyping => _messageController.text.trim().isNotEmpty;

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    if (widget.conversationId != null) {
      final result = await AuthService.getMessages(widget.conversationId!, 1);
      if (mounted && result['success']) {
        final loaded = List<Map<String, dynamic>>.from(result['data']);
        _updateMessages(loaded);
      }
    } else {
      // محاولة جلب المحادثة الحالية مع المستخدم
      await _tryLoadOrCreateConversation();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _tryLoadOrCreateConversation() async {
    final result = await AuthService.getConversations();
    if (result['success']) {
      final conversations = List<Map<String, dynamic>>.from(
        result['data'] ?? [],
      );
      final existing = conversations.firstWhereOrNull(
        (c) => c['other_user_id'] == widget.otherUserId,
      );
      if (existing != null) {
        // وُجدت محادثة → استخدمها
        final msgResult = await AuthService.getMessages(
          existing['conversation_id'],
          1,
        );
        if (msgResult['success']) {
          final loaded = List<Map<String, dynamic>>.from(msgResult['data']);
          _updateMessages(loaded);
        }
      } else {
        // لا توجد محادثة → اعرض فارغ
        _updateMessages([]);
      }
    } else {
      _updateMessages([]);
    }
  }

  void _updateMessages(List<Map<String, dynamic>> newMessages) {
    setState(() {
      _messages = newMessages;
      if (_messages.isNotEmpty) {
        _lastMessageId = _messages.last['id'].toString();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _loadMessagesSilently() async {
    if (widget.conversationId != null) {
      final result = await AuthService.getMessages(widget.conversationId!, 1);
      if (mounted && result['success']) {
        final newMessages = List<Map<String, dynamic>>.from(result['data']);
        _checkAndUpdate(newMessages);
      }
    } else {
      await _tryLoadOrCreateConversationSilently();
    }
  }

  Future<void> _tryLoadOrCreateConversationSilently() async {
    final result = await AuthService.getConversations();
    if (result['success']) {
      final conversations = List<Map<String, dynamic>>.from(
        result['data'] ?? [],
      );
      final existing = conversations.firstWhereOrNull(
        (c) => c['other_user_id'] == widget.otherUserId,
      );
      if (existing != null) {
        final msgResult = await AuthService.getMessages(
          existing['conversation_id'],
          1,
        );
        if (msgResult['success']) {
          final newMessages = List<Map<String, dynamic>>.from(
            msgResult['data'],
          );
          _checkAndUpdate(newMessages);
        }
      }
    }
  }

  void _checkAndUpdate(List<Map<String, dynamic>> newMessages) {
    if (newMessages.isEmpty) return;
    final newLastId = newMessages.last['id'].toString();
    if (newLastId != _lastMessageId) {
      _lastMessageId = newLastId;
      setState(() {
        _messages = newMessages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();
    final result = await AuthService.sendMessage(widget.otherUserId, content);
    if (result['success'] && result['data'] != null) {
      final newMsg = Map<String, dynamic>.from(result['data']['message']);
      setState(() {
        _messages.add(newMsg);
        _lastMessageId = newMsg['id'].toString();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      if (widget.conversationId == null) {}
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة')));
    }
    setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final bool isMe = message['sender_id'] ==
                          AuthService.currentUser?['user_id'];
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message['content'],
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  // تم حذف _checkAndShowDisclaimer لأنها كانت في ChatPage الأصلية
}
