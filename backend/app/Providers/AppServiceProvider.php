<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot()
    {
        // ====> حل نهائي للمشكلة في بيئة الاستضافة <====
        // في كل طلب، نتأكد من أن OPcache يقرأ أحدث نسخة من ملفات النماذج.
        // هذا يحل مشكلة الكاش التي تمنع Laravel من رؤية التغييرات.
        if (function_exists('opcache_reset')) {
            opcache_reset();
        }
        // =======================================================
    }
}
