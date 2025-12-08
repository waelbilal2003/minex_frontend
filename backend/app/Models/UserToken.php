<?php

namespace App\Models;

use Laravel\Sanctum\PersonalAccessToken;

class UserToken extends PersonalAccessToken
{
    // لا حاجة لتحديد $table بعد الآن
}