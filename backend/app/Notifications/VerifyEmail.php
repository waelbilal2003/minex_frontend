<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class VerifyEmail extends Notification
{
    use Queueable;

    public function __construct()
    {
        //
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify', // اسم المسار الذي سننشئه
            now()->addMinutes(60), // صلاحية الرابط 60 دقيقة
            ['id' => $notifiable->getKey(), 'hash' => sha1($notifiable->getEmailForVerification())]
        );

        return (new MailMessage)
            ->subject('تأكيد عنوان بريدك الإلكتروني')
            ->greeting('مرحباً!')
            ->line('الرجاء الضغط على الزر أدناه لتأكيد عنوان بريدك الإلكتروني.')
            ->action('تأكيد البريد الإلكتروني', $verificationUrl)
            ->line('إذا لم تقم بإنشاء هذا الحساب، فلا داعي لاتخاذ أي إجراء آخر.')
            ->salutation('مع تحيات فريق Minex');
    }

    public function toArray($notifiable)
    {
        return [
            //
        ];
    }
}