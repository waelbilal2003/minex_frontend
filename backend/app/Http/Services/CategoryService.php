<?php

namespace App\Http\Services;

use App\Models\Category;
use App\Models\Post;

class CategoryService
{
    /**
     * جلب الفئات أو جلب المنشورات الخاصة بفئة معينة.
     *
     * @param int|null $categoryId
     * @return array
     */
    public function getCategories($categoryId = null)
    {
        try {
            // إذا تم توفير categoryId، قم بجلب المنشورات الخاصة بهذه الفئة
            if ($categoryId) {
                // --- التغيير الرئيسي هنا ---
                // نبحث عن المنشورات التي تحتوي على المفتاح الأجنبي category_id
                // بدلاً من البحث عن اسم الفئة، وهو الأداء والأكثر موثوقية.
                $posts = Post::with('user')
                    ->where('category_id', $categoryId)
                    ->get()
                    ->map(function ($post) {
                        // === معالجة الصور ===
                        $images = [];
                        if (!empty($post->images)) {
                            if (is_string($post->images)) {
                                $decoded = json_decode($post->images, true);
                                if (is_array($decoded)) {
                                    $images = $decoded;
                                }
                            } elseif (is_array($post->images)) {
                                $images = $post->images;
                            }
                        }

                        // تحويل كل صورة إلى رابط مطلق
                        $post->images = array_map(function ($path) {
                            if (str_starts_with($path, 'http')) {
                                return $path;
                            }
                            return asset('storage/' . ltrim($path, '/'));
                        }, $images);

                        // === معالجة الفيديو ===
                        if (!empty($post->video_url)) {
                            if (!str_starts_with($post->video_url, 'http')) {
                                $post->video_url = asset('storage/' . ltrim($post->video_url, '/'));
                            }
                        }

                        return $post;
                    });

                // جلب بيانات الفئة نفسها لإضافتها في الاستجابة
                $category = Category::findOrFail($categoryId, ['id', 'name']);

                return [
                    'success' => true,
                    'message' => 'تم جلب المنشورات للتصنيف بنجاح',
                    'data' => [
                        'category' => $category->only(['id', 'name']),
                        'posts' => $posts
                    ]
                ];
            }

            // إذا لم يتم توفير categoryId، قم بجلب جميع الفئات
            $categories = Category::orderBy('name')->get(['id', 'name']); // تحديد الأعمدة المطلوبة فقط

            return [
                'success' => true,
                'message' => 'تم جلب جميع الفئات بنجاح',
                'data' => ['categories' => $categories]
            ];
        } catch (\Exception $e) {
            // في بيئة التطوير، يمكنك طباعة الخطأ كاملاً
            // في بيئة الإنتاج، يفضل تسجيل الخطأ في ملفات الـ log
            // Log::error($e);
            return [
                'success' => false,
                'message' => 'حدث خطأ ما: ' . $e->getMessage()
            ];
        }
    }
}