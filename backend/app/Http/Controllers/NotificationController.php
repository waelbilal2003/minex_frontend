<?php

namespace App\Http\Controllers;

use App\Http\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function __construct(protected NotificationService $service)
    {
    }

    /**
     * إرسال إشعار لجميع المستخدمين
     * POST /api/notifications/send-to-all
     */
    public function sendToAll(Request $request)
    {
        return $this->service->sendToAllUsers($request);
    }
}
