<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Http\Services\PostService;
use App\Http\Requests\CreatePostRequest;

class PostController extends Controller
{
       protected $postService;

    public function __construct(PostService $postService)
    {
        $this->postService = $postService;
    }
    public function create(CreatePostRequest $request)
    {
        $result = $this->postService->createPost($request);
        return response()->json($result, $result['success'] ? 200 : 400);
    }
       public function index(Request $request)
    {
        $result = $this->postService->getPosts($request);
        return response()->json($result);
    }
    public function getAll(Request $request)
{
    $result = $this->postService->getAllPosts($request);
    return response()->json($result);
}
public function delete(Request $request)
{
    $result = $this->postService->deletePost($request);
    return response()->json($result);
}


public function toggleLike(Request $request)
{
    $result = $this->postService->toggleLike($request);
    return response()->json($result);
}

public function show(Request $request, $id)
{
    $result = $this->postService->getPostById($request, $id);

    // إذا كانت النتيجة غير ناجحة (المنشور غير موجود)، أرجع خطأ 404
    if (!$result['success']) {
        return response()->json($result, 404);
    }

    // في حالة النجاح، أرجع النتيجة مع رمز الحالة الافتراضي 200
    return response()->json($result);
}
}
