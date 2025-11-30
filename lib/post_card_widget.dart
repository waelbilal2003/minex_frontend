import 'dart:async'; // <-- ✨ تم إضافة هذا الاستيراد لاستخدام Timer
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth_service.dart';
import 'comments_page.dart';
import 'home_page.dart'; // لاستخدام VideoPlayerWidget
import 'user_profile_page.dart';
import 'login_page.dart';
import 'full_screen_image_viewer.dart';
import 'messages_page.dart'; // <-- ✨ تم إضافة هذا الاستيراد للوصول إلى ChatPage
import 'post_helpers.dart'; // <-- ✨ استيراد الدوال المساعدة المركزية
import 'package:shared_preferences/shared_preferences.dart'; // <-- ✨ لحفظ المفضلة محلياً
import 'dart:convert'; // <-- ✨ لتحويل JSON
import 'package:share_plus/share_plus.dart';

class PostCardWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onDelete;

  const PostCardWidget({Key? key, required this.post, this.onDelete})
      : super(key: key);

  @override
  _PostCardWidgetState createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_posts') ?? '[]';
      final List<dynamic> favoritesList = json.decode(favoritesJson);

      final isFav = favoritesList.any((fav) => fav['id'] == widget.post['id']);

      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    } catch (e) {
      print('خطأ في فحص المفضلة');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_posts') ?? '[]';
      List<dynamic> favoritesList = json.decode(favoritesJson);

      if (_isFavorite) {
        // إزالة من المفضلة
        favoritesList.removeWhere((fav) => fav['id'] == widget.post['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إزالة المنشور من المفضلة'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // إضافة للمفضلة
        favoritesList.add(widget.post);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة المنشور للمفضلة'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // حفظ التغييرات
      await prefs.setString('favorite_posts', json.encode(favoritesList));

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      print('خطأ في تحديث المفضلة');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ في تحديث المفضلة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog(BuildContext context, int postId) {
    String selectedReason = '';
    String description = '';
    final reasons = [
      'محتوى غير لائق',
      'رسائل مسيئة أو تحرش',
      'بيع مواد ممنوعة',
      'احتيال أو نصب',
      'انتهاك حقوق الطبع والنشر',
      'محتوى مضلل',
      'أخرى',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إبلاغ عن المنشور'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ما سبب الإبلاغ عن هذا المنشور؟'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'سبب الإبلاغ',
                        border: OutlineInputBorder(),
                      ),
                      items: reasons
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedReason = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'تفاصيل إضافية (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedReason.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(context);
                          final result = await AuthService.reportPost(
                            postId: postId,
                            reason: selectedReason,
                            description:
                                description.isEmpty ? null : description,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    (result['success']
                                        ? 'تم إرسال الإبلاغ بنجاح'
                                        : 'خطأ في الإرسال'),
                              ),
                              backgroundColor:
                                  result['success'] ? Colors.green : Colors.red,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('إرسال الإبلاغ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePost(BuildContext context, int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف هذا المنشور نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await AuthService.deletePost(postId);
      if (result['success'] == true) {
        widget.onDelete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المنشور بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل حذف المنشور'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ استخدام الدالة المركزية من PostHelpers
  String _getImageUrl(String path) {
    return PostHelpers.getFullImageUrl(path, AuthService.baseUrl);
  }

  void _openImageViewer(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = widget.post['is_liked_by_user'] ??
        false; // تم التصحيح: is_liked_by_user
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = (AuthService.currentUser?['gender'] ?? 'ذكر') == 'ذكر'
        ? Colors.blue
        : Colors.pink;

    // --- تعديلات الوصول إلى بيانات المستخدم ---
    final userData = widget.post['user'] as Map<String, dynamic>?;
    final currentUserId = AuthService.currentUser?['user_id'];
    final postUserId = userData?['id'] is int
        ? userData!['id']
        : int.tryParse(userData?['id'].toString() ?? '') ?? -1;
    final canDelete = AuthService.isAdmin || currentUserId == postUserId;

    final createdAt = DateTime.parse(widget.post['created_at']);
    final timeAgo = DateFormat('yyyy-MM-dd – kk:mm').format(createdAt);

    final userType = userData?['user_type'] ?? 'person';
    final gender = (userData?['gender'] ?? '').toString().toLowerCase();

    final Color avatarColor;
    final IconData avatarIcon;

    if (userType == 'store') {
      avatarColor = Colors.amber.shade700;
      avatarIcon = Icons.storefront;
    } else {
      if (gender == 'ذكر' || gender == 'male' || gender == 'm') {
        avatarColor = Colors.blue;
        avatarIcon = Icons.man;
      } else {
        avatarColor = Colors.pink;
        avatarIcon = Icons.woman;
      }
    }

    void navigateToUserProfile() {
      if (postUserId == -1) return;
      // لا تنتقل إلى الصفحة إذا كنت فيها بالفعل
      if (ModalRoute.of(context)?.settings.name == 'UserProfilePage' &&
          ModalRoute.of(context)?.settings.arguments == postUserId) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfilePage(
            userId: postUserId,
            userName: userData?['full_name'], // تم التصحيح
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: navigateToUserProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    child: Icon(avatarIcon, color: Colors.white, size: 22),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: navigateToUserProfile,
                        child: Text(
                          userData?['full_name'] ?? 'مستخدم', // تم التصحيح
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.post['category'] != null &&
                    widget.post['category'].isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.post['category'],
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deletePost(context, widget.post['id']);
                    }
                    if (value == 'report') {
                      if (!AuthService.isLoggedIn) {
                        _showLoginRequiredDialog(context);
                      } else {
                        _showReportDialog(context, widget.post['id']);
                      }
                    }
                    if (value == 'favorite') {
                      if (!AuthService.isLoggedIn) {
                        _showLoginRequiredDialog(context);
                      } else {
                        _toggleFavorite();
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (canDelete)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'حذف المنشور',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    if (!canDelete)
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'إبلاغ',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    // ✨ خيار إضافة/إزالة من المفضلة
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                            style: TextStyle(
                              color:
                                  _isFavorite ? Colors.red : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (widget.post['content'] != null &&
              widget.post['content'].isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(widget.post['content']),
            ),
          if (widget.post['price'] != null || widget.post['location'] != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  if (widget.post['price'] != null)
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          widget.post['price'].toString(),
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  if (widget.post['price'] != null &&
                      widget.post['location'] != null)
                    SizedBox(width: 12),
                  if (widget.post['location'] != null)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          widget.post['location'],
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (widget.post['images'] != null &&
              (widget.post['images'] as List).isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _buildImagesWidget(widget.post['images']),
            ),
          if (widget.post['video'] != null &&
              widget.post['video']['video_path'] != null) // تم التصحيح
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _buildVideoPlayer(
                  widget.post['video']['video_path']), // تم التصحيح
            ),
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInteractionButton(
                  text: '${widget.post['likes_count'] ?? 0} إعجاب',
                  icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: isLiked
                      ? primaryColor
                      : (isDarkMode ? Colors.white : Colors.grey[800]!),
                  onTap: () async {
                    if (!AuthService.isLoggedIn) {
                      _showLoginRequiredDialog(context);
                      return;
                    }

                    bool currentIsLiked =
                        widget.post['is_liked_by_user'] ?? false;
                    int currentLikesCount = widget.post['likes_count'] ?? 0;

                    widget.post['is_liked_by_user'] = !currentIsLiked;
                    widget.post['likes_count'] = currentLikesCount +
                        (widget.post['is_liked_by_user'] ? 1 : -1);

                    if (mounted) setState(() {});

                    try {
                      final result = await AuthService.togglePostLike(
                        widget.post['id'],
                      );
                      if (result['success'] == true && mounted) {
                        widget.post['is_liked_by_user'] = result['isLiked'] ??
                            widget.post['is_liked_by_user'];
                        widget.post['likes_count'] = result['likesCount'] ??
                            result['likes_count'] ??
                            widget.post['likes_count'];
                        setState(() {});
                      } else {
                        widget.post['is_liked_by_user'] = currentIsLiked;
                        widget.post['likes_count'] = currentLikesCount;
                        if (mounted) setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? 'فشل تحديث الإعجاب',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      widget.post['is_liked_by_user'] = currentIsLiked;
                      widget.post['likes_count'] = currentLikesCount;
                      if (mounted) setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ في تحديث الإعجاب'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                _buildInteractionButton(
                  text: '${widget.post['comments_count'] ?? 0} تعليق',
                  icon: Icons.comment_outlined,
                  color: isDarkMode ? Colors.white : Colors.grey[800]!,
                  onTap: _navigateToComments,
                ),
                _buildInteractionButton(
                  text: 'مراسلة',
                  icon: Icons.message_outlined,
                  color: isDarkMode ? Colors.white : Colors.grey[800]!,
                  onTap: () {
                    if (!AuthService.isLoggedIn) {
                      _showLoginRequiredDialog(context);
                      return;
                    }
                    if (currentUserId == postUserId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('لا يمكنك مراسلة نفسك!')),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          conversationId: -1,
                          otherUserId: postUserId,
                          otherUserName: userData?['full_name'], // تم التصحيح
                          otherUserGender: userData?['gender'], // تم التصحيح
                        ),
                      ),
                    );
                  },
                ),
                _buildInteractionButton(
                  text: 'مشاركة',
                  icon: Icons.share_outlined,
                  color: isDarkMode ? Colors.white : Colors.grey[800]!,
                  onTap: () async {
                    try {
                      final postId = widget.post['id'];
                      final postTitle = widget.post['title'] ??
                          widget.post['content']?.substring(0, 30) ??
                          'منشور';
                      final url = 'https://minexsy.site/api/posts/$postId';

                      final shareText =
                          'شاهد هذا المنشور: "$postTitle" على تطبيق minex\n$url';

                      await Share.share(shareText, subject: 'مشاركة منشور');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'حدث خطأ أثناء المشاركة: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم تبسيطها بشكل كبير
  Widget _buildInteractionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              // ✨ تم تبسيط النص ليعرض دائمًا
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl, List<String> allImageUrls) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: GestureDetector(
        onTap: () => _openImageViewer(context, allImageUrls, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: _getImageUrl(imageUrl),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoImages(List<dynamic> images, List<String> allImageUrls) {
    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(context, allImageUrls, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(images[0]),
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTap: () => _openImageViewer(context, allImageUrls, 1),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(images[1]),
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeImages(List<dynamic> images, List<String> allImageUrls) {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImageViewer(context, allImageUrls, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(images[0]),
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 1),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[1]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 2),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[2]),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourImages(List<dynamic> images, List<String> allImageUrls) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[0]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 1),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[1]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 2),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[2]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 3),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[3]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleImages(List<dynamic> images, List<String> allImageUrls) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[0]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 1),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[1]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 2),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _getImageUrl(images[2]),
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, allImageUrls, 3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _getImageUrl(images[3]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+${images.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildImagesWidget(List<dynamic> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final List<String> allImageUrls =
        images.map((img) => _getImageUrl(img.toString())).toList();

    switch (images.length) {
      case 1:
        return _buildSingleImage(images[0], allImageUrls);
      case 2:
        return _buildTwoImages(images, allImageUrls);
      case 3:
        return _buildThreeImages(images, allImageUrls);
      case 4:
        return _buildFourImages(images, allImageUrls);
      default:
        return _buildMultipleImages(images, allImageUrls);
    }
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مطلوب تسجيل الدخول'),
        content: const Text('يجب عليك تسجيل الدخول أولاً لاستخدام هذه الميزة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  void _navigateToComments() async {
    if (!AuthService.isLoggedIn) {
      _showLoginRequiredDialog(context);
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CommentsPage(
          postId: widget.post['id'],
          postTitle: widget.post['content'] ?? widget.post['title'] ?? '',
        ),
      ),
    );
    if (result == true) {
      // بعد العودة، نعيد تحميل المنشور كاملاً من الخادم عبر إعادة بناء الـ HomePage
      // لكن بما أننا لا نتحكم هنا في HomePage، نكتفي بتحديث العداد يدويًا إذا أردت:
      _refreshCommentsCount();
    }
  }

  Future<void> _refreshCommentsCount() async {
    try {
      final result = await AuthService.getComments(widget.post['id']);
      if (result['success'] == true && mounted) {
        // نُحدّث القيمة في widget.post مباشرة
        widget.post['comments_count'] =
            result['total_comments'] ?? result['comments_count'] ?? 0;
        // لا حاجة لـ setState لأننا سنعتمد على widget.post في العرض
      }
    } catch (e) {
      print('❌ خطأ في تحديث عدد التعليقات');
    }
  }
}
