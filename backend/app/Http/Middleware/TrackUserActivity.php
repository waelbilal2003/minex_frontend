<?php

namespace App\Http\Middleware;

use App\Http\Services\UserActivityService; // لم نعد بحاجة إلى TokenService
use Closure;
use Illuminate\Http\Request;

class TrackUserActivity
{
    public function __construct(
        protected UserActivityService $activityService
    ) {
        // لم نعد بحاجة إلى TokenService في الـ constructor
    }

    /**
     * معالجة الطلب لتتبع نشاط المستخدم
     */
    public function handle(Request $request, Closure $next)
    {
        // auth:sanctum يتأكد من وجود المستخدم، لا حاجة للتحقق يدويًا
        $user = $request->user();

        if ($user) {
            // تحديث نشاط المستخدم
            $this->activityService->updateUserActivity($user->id);

            // تمرير معرف المستخدم في الطلب (إذا كنت لا تزال تحتاجه في أماكن أخرى)
            $request->merge(['user_id' => $user->id]);
            $request->merge(['auth_user' => $user]);
        }

        return $next($request);
    }
}