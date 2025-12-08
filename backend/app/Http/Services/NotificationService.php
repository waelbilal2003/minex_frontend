<?php

namespace App\Http\Services;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    public function __construct(
        protected TokenService $tokenService,
        protected FirebaseNotificationService $firebaseService
    ) {
    }

    /**
     * إرسال إشعار لجميع المستخدمين
     */
    public function sendToAllUsers(Request $request)
    {
        // التحقق من صلاحيات الأدمن
        $token = $this->tokenService->getBearerToken($request);
        if (!$token) {
            return $this->sendResponse(false, 'التوكن مطلوب');
        }

        $user = $this->tokenService->validateToken($token);
        if (!$user) {
            return $this->sendResponse(false, 'التوكن غير صالح');
        }

        // التحقق من أن المستخدم أدمن
        if ($user->is_admin != 1) {
            return $this->sendResponse(false, 'ليس لديك صلاحيات إدارية');
        }

        // الحصول على البيانات
        $title = $request->input('title');
        $body = $request->input('body');

        if (empty($title) || empty($body)) {
            return $this->sendResponse(false, 'العنوان والمحتوى مطلوبان');
        }

        try {
            // جلب جميع معرفات المستخدمين النشطين
            $userIds = DB::table('users')
                ->where('is_active', 1)
                ->pluck('id')
                ->toArray();

            if (empty($userIds)) {
                return $this->sendResponse(false, 'لا يوجد مستخدمون نشطون');
            }

            // إرسال الإشعار لكل مستخدم
            $successCount = 0;
            $failureCount = 0;

            foreach ($userIds as $userId) {
                try {
                    $result = $this->firebaseService->sendToUser(
                        $userId,
                        $title,
                        $body,
                        [
                            'type' => 'admin_notification',
                            'sent_at' => now()->toIso8601String()
                        ]
                    );

                    if ($result) {
                        $successCount++;
                    } else {
                        $failureCount++;
                    }
                } catch (\Exception $e) {
                    $failureCount++;
                    Log::error("Failed to send notification to user_id={$userId}: " . $e->getMessage());
                }
            }

            $message = "تم إرسال الإشعار بنجاح إلى {$successCount} مستخدم";
            if ($failureCount > 0) {
                $message .= " (فشل الإرسال إلى {$failureCount} مستخدم)";
            }

            return $this->sendResponse(true, $message, [
                'total_users' => count($userIds),
                'success_count' => $successCount,
                'failure_count' => $failureCount
            ]);

        } catch (\Exception $e) {
            Log::error("Error in sendToAllUsers: " . $e->getMessage());
            return $this->sendResponse(false, 'خطأ في إرسال الإشعارات: ' . $e->getMessage());
        }
    }

    private function sendResponse($success, $message, $data = [])
    {
        return response()->json([
            'success' => $success,
            'message' => $message,
            'data' => $data,
        ]);
    }
}
