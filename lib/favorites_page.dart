import 'package:flutter/material.dart';
import 'post_card_widget.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoritePosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_posts') ?? '[]';
      final List<dynamic> favoritesList = json.decode(favoritesJson);

      if (mounted) {
        setState(() {
          _favoritePosts = List<Map<String, dynamic>>.from(favoritesList);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('حدث خطأ في الاتصال');
      if (mounted) {
        setState(() {
          _favoritePosts = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = (AuthService.currentUser?['gender'] ?? 'ذكر') == 'ذكر'
        ? Colors.blue
        : Colors.pink;

    if (!AuthService.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'المفضلة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'يجب تسجيل الدخول لعرض المفضلة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('المفضلة'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_favoritePosts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'مسح جميع المفضلة',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('تأكيد المسح'),
                    content: Text('هل تريد حذف جميع المنشورات من المفضلة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('حذف الكل',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('favorite_posts', '[]');
                  setState(() {
                    _favoritePosts = [];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم مسح جميع المفضلة')),
                  );
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _favoritePosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد منشورات مفضلة',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'قم بإضافة منشورات للمفضلة لتظهر هنا',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoritePosts.length,
                    itemBuilder: (context, index) {
                      return PostCardWidget(
                        key: ValueKey(_favoritePosts[index]['id']),
                        post: _favoritePosts[index],
                        onDelete: () {
                          setState(() {
                            _favoritePosts.removeAt(index);
                          });
                          // حفظ التغييرات
                          _saveFavorites();
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(_favoritePosts);
      await prefs.setString('favorite_posts', favoritesJson);
    } catch (e) {
      print('حدث خطأ في الاتصال');
    }
  }
}
