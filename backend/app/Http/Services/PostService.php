<?php

namespace App\Http\Services;

use App\Models\Post;
use App\Models\User;
use Illuminate\Support\Facades\DB;
// لم نعد بحاجة إلى Hash و TokenService

class PostService
{
    // تم حذف الـ constructor الذي يستخدم TokenService

    public function createPost($request)
    {
        // Sanctum يضمن أن المستخدم موجود ومصادق عليه
        $user = $request->user();
        if (!$user) {
            return ['success' => false, 'message' => 'المستخدم غير مصادق عليه'];
        }

        // تحديث النشاط
        $user->update(['last_activity' => now()]);

        // رفع الصور
        $images = [];
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $path = $image->store('uploads/posts', 'public');
                $images[] = $path;
            }
        }

        // رفع الفيديو
        $videoPath = null;
        if ($request->hasFile('video')) {
            $videoPath = $request->file('video')->store('uploads/videos', 'public');
        }

        // إنشاء البوست
        $post = Post::create([
            'user_id'   => $user->id,
            'title'     => $request->title,
            'category'  => $request->category,
            'content'   => $request->content,
            'price'     => $request->price,
            'location'  => $request->location,
            'images'    => !empty($images) ? json_encode($images) : null,
            'video_url' => $videoPath,
        ]);

        return [
            'success' => true,
            'message' => 'تم إنشاء المنشور بنجاح',
            'data'    => ['post_id' => $post->id]
        ];
    }

    public function getPosts($request)
    {
        // جلب المستخدم الحالي إذا كان مصادقًا عليه
        $user = $request->user();
        $userId = $user ? $user->id : null;

        // جلب آخر 20 منشور (للجميع، حتى غير المسجلين)
        $posts = Post::with('user:id,full_name,gender,user_type')
            ->orderByDesc('created_at')
            ->limit(20)
            ->get();

        $posts = $posts->map(function ($post) use ($userId) {
            $isLikedByUser = false;
            if ($userId) {
                $isLikedByUser = DB::table('post_likes')
                    ->where('post_id', $post->id)
                    ->where('user_id', $userId)
                    ->exists();
            }

            return [
                'id'              => $post->id,
                'title'           => $post->title,
                'content'         => $post->content,
                'category'        => $post->category,
                'price'           => $post->price,
                'location'        => $post->location,
                'likes_count'     => $post->likes_count,
                'comments_count'  => $post->comments_count,
                'created_at' => $post->created_at->setTimezone('Asia/Damascus')->toDateTimeString(),
                'is_liked_by_user'=> $isLikedByUser,
                'images' => !empty($post->images)
                    ? collect(json_decode($post->images, true))->map(fn($img) => url('storage/' . $img))->toArray()
                    : [],
                'video' => $post->video_url ? [
                    'video_path' => url('storage/' . $post->video_url),
                ] : null,
                'user' => [
                    'id'        => $post->user->id ?? null,
                    'full_name' => $post->user->full_name ?? 'مستخدم',
                    'gender'    => $post->user->gender ?? null,
                    'user_type' => $post->user->user_type ?? null,
                ]
            ];
        });

        return [
            'success' => true,
            'data'    => $posts
        ];
    }

    public function getAllPosts($request)
    {
        $user = $request->user();
        if (!$user || !$user->is_admin) {
            return ['success' => false, 'message' => 'ليس لديك صلاحيات إدارية'];
        }

        try {
            $posts = Post::with('user:id,full_name')
                ->orderBy('created_at', 'desc')
                ->get();

            $posts->transform(function ($post) {
                $post->images = $post->images ? json_decode($post->images, true) : [];
                $post->user_name = $post->user->full_name ?? 'مستخدم';
                unset($post->user);
                return $post;
            });

            return [
                'success' => true,
                'message' => 'تم جلب جميع المنشورات',
                'data'    => ['posts' => $posts]
            ];
        } catch (\Exception $e) {
            return [
                'success' => false,
                'message' => 'خطأ في جلب المنشورات: ' . $e->getMessage()
            ];
        }
    }

    public function deletePost($request)
    {
        $user = $request->user();
        if (!$user) {
            return ['success' => false, 'message' => 'المستخدم غير مصادق عليه'];
        }

        $postId = $request->post_id;
        if (!$postId) {
            return ['success' => false, 'message' => 'معرف المنشور مطلوب'];
        }

        $post = Post::find($postId);
        if (!$post) {
            return ['success' => false, 'message' => 'المنشور غير موجود'];
        }

        $isOwner = ($post->user_id == $user->id);
        $isAdmin = $user->is_admin;

        if (!$isOwner && !$isAdmin) {
            return ['success' => false, 'message' => 'ليس لديك صلاحية لحذف هذا المنشور'];
        }

        try {
            $post->delete();
            return ['success' => true, 'message' => 'تم حذف المنشور بنجاح'];
        } catch (\Exception $e) {
            return ['success' => false, 'message' => 'خطأ في حذف المنشور: ' . $e->getMessage()];
        }
    }

    public function toggleLike($request)
    {
        $user = $request->user();
        if (!$user) {
            return ['success' => false, 'message' => 'المستخدم غير مصادق عليه'];
        }

        $post = Post::find($request->post_id);
        if (!$post) {
            return ['success' => false, 'message' => 'المنشور غير موجود'];
        }

        $alreadyLiked = DB::table('post_likes')
            ->where('post_id', $post->id)
            ->where('user_id', $user->id)
            ->exists();

        if ($alreadyLiked) {
            DB::table('post_likes')
                ->where('post_id', $post->id)
                ->where('user_id', $user->id)
                ->delete();
            $post->decrement('likes_count');
            return [
                'success' => true,
                'message' => 'تم تحديث الإعجاب بنجاح',
                'isLiked' => false,
                'likes_count' => $post->likes_count
            ];
        } else {
            DB::table('post_likes')->insert([
                'post_id' => $post->id,
                'user_id' => $user->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $post->increment('likes_count');
            return [
                'success' => true,
                'message' => 'تم تحديث الإعجاب بنجاح',
                'isLiked' => true,
                'likes_count' => $post->likes_count
            ];
        }
    }
    public function getPostById($request, $postId)
    {
        // جلب المستخدم الحالي إذا كان مصادقًا عليه
        $user = $request->user();
        $userId = $user ? $user->id : null;
    
        // جلب المنشور المحدد
        $post = Post::with('user:id,full_name,gender,user_type')
            ->find($postId);
    
        if (!$post) {
            return [
                'success' => false,
                'message' => 'المنشور غير موجود'
            ];
        }
    
        $isLikedByUser = false;
        if ($userId) {
            $isLikedByUser = DB::table('post_likes')
                ->where('post_id', $post->id)
                ->where('user_id', $userId)
                ->exists();
        }
    
        $postData = [
            'id'              => $post->id,
            'title'           => $post->title,
            'content'         => $post->content,
            'category'        => $post->category,
            'price'           => $post->price,
            'location'        => $post->location,
            'likes_count'     => $post->likes_count,
            'comments_count'  => $post->comments_count,
            'created_at' => $post->created_at->setTimezone('Asia/Damascus')->toDateTimeString(),
            'is_liked_by_user'=> $isLikedByUser,
            'images' => !empty($post->images)
                ? collect(json_decode($post->images, true))->map(fn($img) => url('storage/' . $img))->toArray()
                : [],
            'video' => $post->video_url ? [
                'video_path' => url('storage/' . $post->video_url),
            ] : null,
            'user' => [
                'id'        => $post->user->id ?? null,
                'full_name' => $post->user->full_name ?? 'مستخدم',
                'gender'    => $post->user->gender ?? null,
                'user_type' => $post->user->user_type ?? null,
            ]
        ];
    
        return [
            'success' => true,
            'data'    => $postData
        ];
    }
}