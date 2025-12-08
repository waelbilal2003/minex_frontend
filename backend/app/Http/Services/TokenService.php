<?php

namespace App\Http\Services;

use App\Models\User;
use Laravel\Sanctum\PersonalAccessToken;

class TokenService
{
    /**
     * استخراج التوكن من الهيدر
     */
    public function getBearerToken($request): ?string
    {
        $header = $request->header('Authorization');
        if ($header && preg_match('/Bearer\s(\S+)/', $header, $matches)) {
            return $matches[1];
        }
        return null;
    }

    /**
     * التحقق من التوكن وإرجاع المستخدم إذا كان صالح
     * هذه الدالة تستخدم Sanctum بدلاً من النظام القديم
     */
    public function validateToken(?string $token): ?User
    {
        if (!$token) {
            return null;
        }

        // استخدام نظام Sanctum للتحقق من التوكن
        // Sanctum يستخدم index على token hash مما يجعله سريع جداً
        $accessToken = PersonalAccessToken::findToken($token);

        if (!$accessToken) {
            return null;
        }

        // التحقق من صلاحية التوكن
        if ($accessToken->expires_at && $accessToken->expires_at->isPast()) {
            // حذف التوكن المنتهي
            $accessToken->delete();
            return null;
        }

        // جلب المستخدم المرتبط بالتوكن
        $user = $accessToken->tokenable;

        // التحقق من أن المستخدم موجود ونشط
        if (!$user || !$user->is_active) {
            return null;
        }

        // تحديث آخر استخدام للتوكن
        $accessToken->forceFill(['last_used_at' => now()])->save();

        return $user;
    }

    /**
     * حذف التوكن الحالي (Logout)
     */
    public function revokeToken(?string $token): bool
    {
        if (!$token) {
            return false;
        }

        $accessToken = PersonalAccessToken::findToken($token);

        if ($accessToken) {
            $accessToken->delete();
            return true;
        }

        return false;
    }

    /**
     * حذف جميع التوكنات الخاصة بمستخدم
     */
    public function revokeAllUserTokens(int $userId): bool
    {
        $user = User::find($userId);
        if ($user) {
            $user->tokens()->delete();
            return true;
        }
        return false;
    }

    /**
     * التحقق من صلاحية التوكن وإرجاع بيانات التوكن
     */
    public function getTokenDetails(?string $token): ?array
    {
        if (!$token) {
            return null;
        }

        $accessToken = PersonalAccessToken::findToken($token);

        if (!$accessToken) {
            return null;
        }

        return [
            'id' => $accessToken->id,
            'tokenable_id' => $accessToken->tokenable_id,
            'name' => $accessToken->name,
            'abilities' => $accessToken->abilities,
            'expires_at' => $accessToken->expires_at,
            'last_used_at' => $accessToken->last_used_at,
            'created_at' => $accessToken->created_at,
        ];
    }
}