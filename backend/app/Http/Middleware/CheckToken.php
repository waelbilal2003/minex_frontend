<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Http\Services\TokenService;

class CheckToken
{
    public function __construct(protected TokenService $tokenService)
    {
    }

    /**
     * معالجة الطلب الوارد
     * يتحقق من صحة التوكن باستخدام Sanctum
     */
    public function handle(Request $request, Closure $next)
    {
        // استخراج التوكن من الهيدر
        $token = $this->tokenService->getBearerToken($request);

        // التحقق من وجود التوكن
        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن مفقود',
            ], 401);
        }

        // التحقق من صحة التوكن والحصول على المستخدم
        $user = $this->tokenService->validateToken($token);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'التوكن غير صالح أو انتهت صلاحيته',
            ], 401);
        }

        // التحقق من أن المستخدم نشط
        if (!$user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'الحساب غير مفعل',
            ], 403);
        }

        // تخزين المستخدم في الطلب للوصول إليه في Controllers
        $request->merge(['auth_user' => $user]);
        $request->merge(['user_id' => $user->id]);

        // تعيين المستخدم في Auth
        auth()->setUser($user);

        return $next($request);
    }
}