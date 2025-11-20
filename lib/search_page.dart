import 'package:flutter/material.dart';
import 'post_card_widget_search.dart';
import 'auth_service.dart';
import 'user_profile_page.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery; // ⭐ إضافة متغير لتخزين كلمة البحث الابتدائية
  const SearchPage({Key? key, this.initialQuery = ''})
      : super(key: key); // ⭐ تعيين قيمة افتراضية

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _postResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // ⭐ تعيين القيمة الابتدائية من widget
    if (widget.initialQuery.isNotEmpty) {
      _searchController.text = widget.initialQuery;
      // ⭐ تشغيل البحث مباشرة بعد بناء الواجهة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _convertCategoryToArabic(String category) {
    Map<String, String> categoryMap = {
      'job': 'التوظيف',
      'tenders': 'المناقصات',
      'suppliers': 'الموردين',
      'general_offers': 'العروض العامة',
      'cars': 'السيارات',
      'motorcycles': 'الدراجات النارية',
      'real_estate': 'تجارة العقارات',
      'weapons': 'المستلزمات العسكرية',
      'electronics': 'الهواتف والالكترونيات',
      'electrical': 'الأدوات الكهربائية',
      'house_rent': 'ايجار العقارات',
      'agriculture': 'الثمار والحبوب',
      'food': 'المواد الغذائية',
      'restaurants': 'المطاعم',
      'heating': 'مواد التدفئة',
      'accessories': 'المكياج والاكسسوار',
      'animals': 'المواشي والحيوانات',
      'books': 'الكتب والقرطاسية',
      'home_health': 'الأدوات المنزلية',
      'clothing_shoes': 'الملابس والأحذية',
      'furniture': 'أثاث المنزل',
      'wholesalers': 'تجار الجملة',
      'distributors': 'الموزعين',
      'others': 'أسواق أخرى',
      'suggestions': 'اقتراحات وشكاوي',
      'ad_contact': 'تواصل للإعلانات',
      'الملابس والأحذية': 'الملابس والأحذية',
      'التوظيف': 'التوظيف',
      'المناقصات': 'المناقصات',
    };

    return categoryMap[category] ?? category;
  }

  int _parseToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _userResults = [];
        _postResults = [];
        _hasSearched = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.search(query);
      print('بيانات البحث: $result');

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        List<Map<String, dynamic>> rawPosts = List<Map<String, dynamic>>.from(
          result['data']['posts'] ?? [],
        );

        final processedPosts = rawPosts.map((post) {
          List<String> images = (post['images'] as List<dynamic>?)
                  ?.map((imageUrl) => imageUrl.toString())
                  .toList() ??
              [];

          String? videoUrl = post['video_url'];

          String category = _convertCategoryToArabic(post['category'] ?? '');

          return {
            'id': _parseToInt(post['id']),
            'user_id': _parseToInt(post['user_id']),
            'user_name': post['user_name'] ?? 'مستخدم',
            'content': post['content'] ?? '',
            'title': post['title'] ?? '',
            'category': category,
            'price': post['price']?.toString(),
            'location': post['location'],
            'images': images,
            'video_url': videoUrl,
            'likes_count': _parseToInt(post['likes_count'], defaultValue: 0),
            'comments_count': _parseToInt(
              post['comments_count'],
              defaultValue: 0,
            ),
            'created_at': post['created_at'],
            'isLiked': post['is_liked_by_user'] ?? false,
            'gender': post['user']?['gender'],
            'user_type': post['user']?['user_type'] ?? 'person',
            'user_avatar':
                'https://via.placeholder.com/50x50/cccccc/ffffff?text=${(post['user_name'] ?? 'U').substring(0, 1)}',
          };
        }).toList();

        setState(() {
          _userResults = List<Map<String, dynamic>>.from(
            result['data']['users'] ?? [],
          );
          _postResults = processedPosts;
          _hasSearched = true;
        });
      } else {
        setState(() {
          _userResults = [];
          _postResults = [];
          _hasSearched = true;
        });
        if (mounted && result['message'] != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result['message'])));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في البحث: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                userId: user['id'],
                userName: user['user_name'] ?? user['full_name'] ?? 'مستخدم',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  (user['user_name'] ?? user['full_name'] ?? 'U').substring(
                    0,
                    1,
                  ),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['user_name'] ?? user['full_name'] ?? 'مستخدم',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? user['phone'] ?? 'لا يوجد معلومات اتصال',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        backgroundColor: (AuthService.currentUser?['gender'] ?? 'ذكر') == 'ذكر'
            ? Colors.blue
            : Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن منشورات أو مستخدمين...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(''); // ⭐ مسح النتائج عند مسح الحقل
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (query) =>
                  _performSearch(query), // ⭐ البحث عند الضغط على Enter
              onChanged: (query) {
                // ⭐ (اختياري) يمكنك إضافة تأخير (debounce) هنا لتحسين الأداء
                // أو إزالة البحث التلقائي من onChange إذا لم تكن تريده
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (!_hasSearched &&
                        widget.initialQuery.isEmpty) // ⭐ تعديل الشرط
                    ? Center(child: Text('اكتب في الحقل أعلاه لبدء البحث'))
                    : (_userResults.isEmpty && _postResults.isEmpty)
                        ? Center(
                            child: Text(
                                'لا توجد نتائج لـ "${_searchController.text}"'),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16.0),
                            children: [
                              if (_userResults.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'المستخدمون (${_userResults.length})',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ..._userResults.map(_buildUserCard),
                                const SizedBox(height: 24),
                              ],
                              if (_postResults.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'المنشورات (${_postResults.length})',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                                ..._postResults
                                    .map(
                                      (post) => PostCardWidgetSearch(
                                        post: post,
                                        onDelete: () {
                                          setState(() {
                                            _postResults.removeWhere(
                                              (p) => p['id'] == post['id'],
                                            );
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
