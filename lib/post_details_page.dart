import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'post_card_widget.dart';

class PostDetailsPage extends StatefulWidget {
  final int postId;

  const PostDetailsPage({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await AuthService.getPostById(widget.postId);

      if (result['success'] == true) {
        setState(() {
          _post = result['post'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'فشل في جلب تفاصيل المنشور';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _deletePost() {
    if (_post != null) {
      setState(() {
        _post = null;
      });
      Navigator.pop(context, true); // إرجاع true للإشارة إلى أن المنشور تم حذفه
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل المنشور'),
        backgroundColor: (AuthService.currentUser?['gender'] ?? 'ذكر') == 'ذكر'
            ? Colors.blue
            : Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              if (_post != null) {
                final postId = _post!['id'];
                final postTitle = _post!['title'] ??
                    _post!['content']?.substring(0, 30) ??
                    'منشور';
                final url = 'https://minexsy.site/posts/$postId';

                // نسخ الرابط إلى الحافظة
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ الرابط إلى الحافظة')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchPostDetails,
                          child: Text('إعادة المحاولة'),
                        ),
                        SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('العودة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _post == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'تم حذف هذا المنشور',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('العودة'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPostDetails,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: PostCardWidget(
                          post: _post!,
                          onDelete: _deletePost,
                        ),
                      ),
                    ),
    );
  }
}
