<?php

namespace App\Models;

// 1. أضف هذا السطر
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
// ملاحظة: لا حاجة لاستيراد UserToken هنا

// 2. اجعل الكلاس يرث من MustVerifyEmail
class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'full_name',
        'email',
        'phone',
        'password',
        'gender',
        'is_active',
        'is_admin',
        'user_type',
        'email_verified_at' // 3. أضف هذا الحقل هنا
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime', // 4. أضف هذا السطر
            'password' => 'hashed',
        ];
    }

    /**
     * ملاحظة: علاقة Sanctum الافتراضية هي 'tokens'.
     * إذا كنت تستخدم جدولاً مخصصاً، تأكد من أن كل شيء يعمل كما هو متوقع.
     * الكود الذي قدمته سابقاً صحيح إذا كنت تستخدم موديل UserToken مخصص.
     * public function accessTokens() { ... }
     */

    public function posts()
    {
        return $this->hasMany(Post::class);
    }

    public function likedPosts()
    {
        return $this->belongsToMany(Post::class, 'post_likes')->withTimestamps();
    }
}