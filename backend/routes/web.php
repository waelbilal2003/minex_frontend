<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});



Route::get('/test-firebase-config', function () {
    dd([
        'credentials_file' =>config('firebase.projects.app.credentials.credentials_file'),
        'project_id' =>  config('firebase.projects.app.credentials.project_id'),
    ]);
});


use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Illuminate\Http\Request;
use App\Http\Controllers\AuthController;

Route::get('/test-firebase', function () {
    $factory = (new Factory)
        ->withServiceAccount(storage_path('app/firebase/minex-89268-firebase-adminsdk-fbsvc-41fb1b9d68.json'));

    $messaging = $factory->createMessaging();

    try {
        // استبدلي هذا بالتوكن الفعلي لجهازك
        $token = 'cVw57ADdQBiwvD8xkidQHZ:APA91bESwg7J9Ot410SmLP6puveNHgM8XppU1lQO2L0l4LsYS8C-G2n78mUheNuDK2pOH3Pgk6zA3K-VLiEs5FDaARM2_lE8YP6PnFv7o6yOghw4KnzaGN4';

        $message = CloudMessage::withTarget('token', $token)
            ->withNotification([
                'title' => 'Test Notification',
                'body'  => 'This is a test from server'
            ]);

        $messaging->send($message);

        return "Notification sent successfully!";
    } catch (\Throwable $e) {
        return "Server error: " . $e->getMessage();
    }
});

Route::get('/download', function () {
    return view('download');
});

// صفحة استقبال رابط التحقق من البريد الإلكتروني (تُستخدم في ActionCodeSettings.url)
Route::get('/verify-email', function (Request $request) {
    $full = htmlspecialchars($request->fullUrl(), ENT_QUOTES, 'UTF-8');
    $html = <<<HTML
<!doctype html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>تحقق البريد</title>
</head>
<body>
    <h1>جاري معالجة رابط التحقق...</h1>
    <p>حاول فتح التطبيق. إن لم يفتح، اضغط الزر أدناه.</p>
    <button id="openBtn">فتح التطبيق</button>
    <script>
        const full = "$full";
        const appScheme = "minex://verify-email?link=" + encodeURIComponent(full);
        function tryOpen() {
            window.location = full;
            setTimeout(() => { window.location = appScheme; }, 800);
        }
        document.getElementById('openBtn').addEventListener('click', tryOpen);
        tryOpen();
    </script>
</body>
</html>
HTML;
    return response($html, 200)->header('Content-Type', 'text/html');
});

// دعم POST على نفس المسار لتمكين طلبات التحقق من الـ client بدون CSRF (يستخدم middleware 'api')
Route::post('/verify-email', [AuthController::class, 'verifyFirebaseEmail'])->middleware('api');
