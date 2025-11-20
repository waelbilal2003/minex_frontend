import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:async';
import 'create_post_page.dart';
import 'post_card_widget.dart';
import 'dart:convert';

class PostsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const PostsPage({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);
  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<Map<String, dynamic>> _filteredPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts({bool refresh = false}) async {
    if (refresh) {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _filteredPosts.clear();
        _isLoading = true;
        _hasMore = true;
      });
    }

    try {
      print('📊 جلب المنشورات للقسم ID: ${widget.categoryId}');

      // ✅ التصحيح: استدعاء الدالة الجديدة
      final result = await AuthService.getPostsByCategoryId(
        widget.categoryId, // ✅ نمرر الـ ID كرقم
        page: _currentPage,
      );

      if (!mounted) return;
      // --- ✅ معالجة مرنة لصيغة البيانات القادمة من السيرفر ---
      List<dynamic>? postsList;

      if (result['data'] is Map && result['data']['posts'] is List) {
        postsList = result['data']['posts'];
      } else if (result['data'] is List) {
        // إذا كانت الاستجابة نفسها قائمة بدون 'posts'
        postsList = result['data'];
      } else if (result['data'] is String) {
        // إذا أرسل السيرفر نص JSON بدلاً من Map
        try {
          final decoded = json.decode(result['data']);
          if (decoded is List) postsList = decoded;
          if (decoded is Map && decoded['posts'] is List) {
            postsList = decoded['posts'];
          }
        } catch (e) {
          print('❌ فشل تحليل data كنص JSON: $e');
        }
      }

      if (postsList == null) {
        _showErrorMessage(
          result['message'] ?? 'لم يتم العثور على بيانات منشورات',
        );
        return;
      }

      // ✅ الآن نحللها بشكل آمن
      final newPosts = List<Map<String, dynamic>>.from(postsList);

      final processedNewPosts = newPosts.map((post) {
        // 1. إصلاح معالجة الصور: التعامل مع قائمة النصوص مباشرة
        List<String> images = [];
        final imagesField = post['images'];

        if (imagesField is String) {
          try {
            // نحلل النص إلى قائمة
            final decodedList = json.decode(imagesField) as List;
            images = decodedList.map((e) => e.toString()).toList();
          } catch (e) {
            print('❌ فشل تحليل images من نص JSON: $e');
            images = [];
          }
        } else if (imagesField is List) {
          images = imagesField.map((e) => e.toString()).toList();
        } else {
          images = [];
        }

        String? videoUrl = post['video_url'];

        // 3. معلومات المستخدم
        String userName = post['user']?['full_name'] ?? 'مستخدم';
        int userId = post['user']?['id'] ?? -1;

        return {
          'id': post['id'],
          'user_id': userId,
          'user_name': userName,
          'user_avatar':
              'https://via.placeholder.com/50x50/cccccc/ffffff?text=${userName.isNotEmpty ? userName.substring(0, 1) : 'U'}',
          'content': post['content'] ?? '',
          'title': post['title'] ?? '',
          'category': post['category'] ?? '',
          'price': post['price']?.toString(),
          'location': post['location'],
          'images': images,
          'video_url': videoUrl,
          'likes_count': post['likes_count'] ?? 0,
          'comments_count': post['comments_count'] ?? 0,
          'created_at': post['created_at'],
          'isLiked': post['is_liked_by_user'] ?? false,
          'gender': post['user']?['gender'],
          'user_type': post['user']?['user_type'] ?? 'person',
        };
      }).toList();

      if (mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _filteredPosts = processedNewPosts;
          } else {
            _filteredPosts.addAll(processedNewPosts);
          }
          _hasMore = newPosts.isNotEmpty;
        });
      }
    } catch (e) {
      print("Error fetching posts by category: $e");
      _showErrorMessage("حدث خطأ أثناء الاتصال بالخادم: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    _currentPage++;
    await _fetchPosts();
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _filteredPosts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل المنشورات...'),
                ],
              ),
            )
          : _filteredPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد منشورات في هذا القسم',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _fetchPosts(refresh: true),
                    child: const Text('إعادة تحميل'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchPosts(refresh: true),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostPage(),
                          ),
                        );
                        await _fetchPosts(refresh: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[600]!
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                (AuthService.currentUser?['full_name'] ??
                                        'مستخدم')
                                    .substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'بم تفكر...',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[400]!
                                      : Colors.grey[600]!,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.image,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.video_call,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      // ✨ تم تقليل padding هنا ليتناسب مع الـ margin الخاص بالـ Card
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filteredPosts.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredPosts.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        return PostCardWidget(
                          post: _filteredPosts[index],
                          onDelete: () {
                            setState(() {
                              _filteredPosts.removeWhere(
                                (p) => p['id'] == _filteredPosts[index]['id'],
                              );
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
