<?php

namespace App\Http\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AuthService
{
    /**
     * تسجيل مستخدم جديد
     */
    public function register(array $data)
    {
        $emailOrPhone = $data['email_or_phone'];
        $isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL);

        if (!$isEmail) {
            return [
                'success' => false,
                'message' => 'التسجيل يتطلب بريدًا إلكترونيًا صالحًا.',
                'status'  => 400
            ];
        }

        if (User::where('email', $emailOrPhone)->exists()) {
            return [
                'success' => false,
                'message' => 'هذا البريد الإلكتروني مستخدم بالفعل.',
                'status'  => 409 // Conflict
            ];
        }

        $userType = $data['userType'] ?? 'person';
        if (!in_array($userType, ['person', 'store'])) {
            return [ 'success' => false, 'message' => 'نوع المستخدم غير صالح', 'status'  => 400 ];
        }

        $user = User::create([
            'full_name' => $data['full_name'],
            'email'     => $emailOrPhone,
            'phone'     => null,
            'gender'    => $data['gender'],
            'password'  => Hash::make($data['password']),
            'is_admin'  => false,
            'is_active' => true,
            'user_type' => $userType,
            'email_verified_at' => null, // التأكد من أنه فارغ عند الإنشاء
        ]);

        // إرسال إشعار تأكيد البريد الإلكتروني
        try {
            $user->sendEmailVerificationNotification();
        } catch (\Exception $e) {
            Log::error("فشل إرسال بريد التأكيد إلى {$user->email}: " . $e->getMessage());
            // لا نوقف عملية التسجيل إذا فشل إرسال البريد
        }

        if (!empty($data['device_token'])) {
            \App\Models\DeviceToken::updateOrCreate(
                ['user_id' => $user->id],
                ['device_token' => $data['device_token']]
            );
        }

        return [
            'success' => true,
            'message' => 'تم التسجيل بنجاح! يرجى التحقق من بريدك الإلكتروني لتفعيل حسابك.',
            'user'    => null, // لا نرجع بيانات المستخدم إلا بعد تسجيل الدخول
            'status'  => 201
        ];
    }

   /**
     * تسجيل دخول المستخدم
     */
    public function login(array $data, Request $request)
    {
        $emailOrPhone = $data['email_or_phone'];
        $password = $data['password'];

        $isEmail = filter_var($emailOrPhone, FILTER_VALIDATE_EMAIL);
        $column = $isEmail ? 'email' : 'phone';
        $value = $isEmail ? $emailOrPhone : $this->formatPhone($emailOrPhone);

        $user = User::where($column, $value)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return [
                'success' => false,
                'message' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
                'status'  => 401
            ];
        }

        // --- الجزء الأهم ---
        // التحقق مما إذا كان البريد الإلكتروني قد تم تأكيده
        if ($isEmail && !$user->hasVerifiedEmail()) {
            return [
                'success' => false,
                'message' => 'email_not_verified', // رسالة خاصة ليعالجها التطبيق
                'status'  => 403 // Forbidden
            ];
        }
        // --- نهاية الجزء الهام ---

        $token = $user->createToken('auth_token', ['*'])->plainTextToken;

        if ($request->filled('device_token')) {
            \App\Models\DeviceToken::updateOrCreate(
                ['user_id' => $user->id],
                ['device_token' => $request->device_token]
            );
        }

        return [
            'success' => true,
            'message' => 'تم تسجيل الدخول بنجاح',
            'data' => [
                'user_id'    => $user->id,
                'full_name'  => $user->full_name,
                'email'      => $user->email,
                'phone'      => $user->phone,
                'gender'     => $user->gender,
                'is_admin'   => $user->is_admin,
                'user_type'  => $user->user_type,
                'token'      => $token,
            ],
            'status'  => 200
        ];
    }

    /**
     * إعادة إرسال بريد التأكيد
     */
    public function resendVerification(Request $request): array
    {
        $request->validate(['email' => 'required|email']);
        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return [ 'success' => false, 'message' => 'لا يمكننا العثور على مستخدم بهذا البريد.', 'status' => 404 ];
        }

        if ($user->hasVerifiedEmail()) {
            return [ 'success' => false, 'message' => 'هذا البريد تم تأكيده بالفعل.', 'status' => 400 ];
        }

        try {
            $user->sendEmailVerificationNotification();
        } catch (\Exception $e) {
            Log::error("فشل إعادة إرسال بريد التأكيد إلى {$user->email}: " . $e->getMessage());
            return [ 'success' => false, 'message' => 'فشل إرسال البريد. حاول مرة أخرى.', 'status' => 500 ];
        }

        return [ 'success' => true, 'message' => 'تم إرسال رابط تفعيل جديد إلى بريدك.', 'status' => 200 ];
    }
    
    // باقي الدوال تبقى كما هي بدون تغيير...
    public function verifyToken(string $token) { /* ... */ }
    public function forgotPassword(string $emailOrPhone): array { /* ... */ }
    private function formatPhone($phone) { /* ... */ }
    private function formatPhoneNumber(string $phone): string { /* ... */ }
}