<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\VipAdController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SearchController;
use App\Http\Controllers\CommentController;
use App\Http\Controllers\MessageController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\CommentLikeController;
use App\Http\Controllers\ConversationController;
use App\Http\Controllers\AppStatisticsController;
use App\Http\Controllers\NotificationController;
use App\Models\User;
use Illuminate\Auth\Events\Verified;

/*
|--------------------------------------------------------------------------
| Routes بدون حماية (Public Routes)
|--------------------------------------------------------------------------
*/

// ✅ جلب المنشورات — بدون توكن
Route::get('/posts', [PostController::class, 'index']);
Route::get('/categories/{id?}', [CategoryController::class, 'index']);

// ✅ جلب الإعلانات المميزة العامة — بدون توكن
Route::get('/vip-ads/public', [VipAdController::class, 'getVipAdsPublic']);
Route::get('/vip-ads/details', [VipAdController::class, 'getVipAdDetails']);

// إرسال إشعار لجميع المستخدمين (admin only)
Route::post('/notifications/sendtoall', [NotificationController::class, 'sendtoall']);

// اصلاح بطئ الرسائل
Route::get('/conversations/start', [ConversationController::class, 'startConversation']);

// زر المشاركة
 Route::get('/posts/{id}', [PostController::class, 'show']);


/*
|--------------------------------------------------------------------------
| Routes للمصادقة (Authentication Routes)
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:100,1');
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:100,1');
Route::post('/verify_token', [AuthController::class, 'verifyToken']);
// مسار للتحقق من البريد بعد المصادقة عبر Firebase ID token
Route::post('/verify-email', [AuthController::class, 'verifyFirebaseEmail']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
// 1. المسار الذي يضغط عليه المستخدم في بريده الإلكتروني
Route::get('/email/verify/{id}/{hash}', function (Request $request) {
    $user = User::find($request->route('id'));

    if (!hash_equals((string) $request->route('hash'), sha1($user->getEmailForVerification()))) {
        return response()->json(['message' => 'رابط تفعيل غير صالح.'], 403);
    }

    if ($user->hasVerifiedEmail()) {
        return response()->json(['message' => 'البريد الإلكتروني مؤكد بالفعل.'], 200);
    }

    if ($user->markEmailAsVerified()) {
        event(new Verified($user));
    }

    // يمكنك هنا إعادة توجيه المستخدم إلى صفحة "تم التأكيد بنجاح"
    return response('<h1>تم تأكيد بريدك الإلكتروني بنجاح! يمكنك الآن العودة إلى التطبيق وتسجيل الدخول.</h1>');

})->middleware(['signed', 'throttle:6,1'])->name('verification.verify');


// 2. المسار الذي يستدعيه تطبيق Flutter لإعادة إرسال البريد
Route::post('/email/resend-verification', [AuthController::class, 'resendVerificationEmail'])
    ->middleware('throttle:6,1');

/*
|--------------------------------------------------------------------------
| Routes المحمية (Protected Routes)
|--------------------------------------------------------------------------
| يمكنك استخدام أحد الخيارين:
| 1. Middleware المخصص: ['track.activity', 'throttle:100,1', 'check_expire']
| 2. Sanctum الأصلي: ['auth:sanctum', 'throttle:100,1']
|
| للحصول على أفضل أداء، استخدم auth:sanctum
| للحفاظ على التوافق مع الكود القديم، استخدم check_expire
*/

// استخدام Sanctum (موصى به للأداء الأفضل)
Route::middleware(['auth:sanctum', 'track.activity', 'throttle:100,1'])->group(function () {
    
    // Change Password Route
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    
    // User Routes
    Route::get('/profile', [UserController::class, 'profile']);
    Route::post('/profile/update', [UserController::class, 'updateProfile']);
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users/toggle-status', [UserController::class, 'toggleUserStatus']);
    Route::post('/users/delete', [UserController::class, 'deleteUser']);
    Route::get('/user/profile-and-posts', [UserController::class, 'getUserProfileAndPosts']);
    
    // Post Routes
    Route::post('/posts/create', [PostController::class, 'create']);
    Route::get('/admin/posts', [PostController::class, 'getAll']);
    Route::delete('/posts/delete', [PostController::class, 'delete']);
    Route::get('/toggleLike', [PostController::class, 'toggleLike']);
    
    // Report Routes
    Route::get('/show/reports/posts', [ReportController::class, 'getReportedPosts']);
    Route::post('/posts/report', [ReportController::class, 'reportPost']);
    Route::post('/reports/update-status', [ReportController::class, 'updateReportStatus']);
    
    // Search Routes
    Route::get('/search', [SearchController::class, 'search']);
    
    // VIP Ads Routes
    Route::get('/vip-ads', [VipAdController::class, 'getVipAds']);
    Route::post('/vip-ads/upload-cover', [VipAdController::class, 'uploadCoverImage']);
    Route::post('/vip-ads/uploadMediaFile', [VipAdController::class, 'uploadMediaFile']);
    Route::post('/vip-ads/createEnhancedVipAd', [VipAdController::class, 'createEnhancedVipAd']);
    Route::delete('/vip-ads/{id}', [VipAdController::class, 'delete']);
    
    // Statistics Routes
    Route::get('/statistics', [AppStatisticsController::class, 'index']);
    Route::get('/statistics/detailed', [AppStatisticsController::class, 'detailed']);
    
    // Comment Routes
    Route::post('/comments/add', [CommentController::class, 'addComment']);
    Route::get('/comments', [CommentController::class, 'getComments']);
    Route::post('/comments/toggle-like', [CommentLikeController::class, 'toggle']);
    
    // Conversation & Message Routes
    Route::get('/conversations', [ConversationController::class, 'getConversations']);
    Route::get('/get/messages', [MessageController::class, 'getMessages']);
    Route::post('/send/messages', [MessageController::class, 'sendMessage']);
});

/*
|--------------------------------------------------------------------------
| Route للتحقق من المستخدم الحالي (Sanctum)
|--------------------------------------------------------------------------
*/
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');