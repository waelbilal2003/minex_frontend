plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")}

android {
    namespace = "com.example.minex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // تم تحديث إصدار NDK هنا

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.minex"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 2
        versionName = flutter.versionName
        multiDexEnabled = true // السطر المضاف لدعم MultiDex 
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// القسم المضاف لحل المشكلة
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // استيراد Firebase BOM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    // إضافة الاعتمادية لـ Firebase Analytics (مثال)
    implementation("com.google.firebase:firebase-analytics")
    // إضافة الاعتمادية لـ Firebase Messaging (ضروري للإشعارات)
    implementation("com.google.firebase:firebase-messaging")
}

flutter {
    source = "../.."
}