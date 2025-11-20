import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // تم تصحيح معرف المكون الإضافي لـ Kotlin ليتوافق مع الكود الناجح
    id("org.jetbrains.kotlin.android") 
    // يجب أن يكون مكون Flutter الإضافي بعد Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // com.google.gms.google-services سيتم تطبيقه في نهاية الملف
}

// ✅ تم نقل تعريف keystoreProperties إلى خارج كتلة android ليكون في المستوى الأعلى، كما في الكود الناجح
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.minex"
    // استخدام flutter.compileSdkVersion يفضل استخدام رقم ثابت مثل 34
    compileSdk = 34 
    // استخدام flutter.ndkVersion هو الأفضل للتوافق
    ndkVersion = flutter.ndkVersion 

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.minex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    
    // ✅ تم تصحيح قسم التوقيع ليتطابق تماماً مع الكود الناجح ويعالج مشكلة null
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            // ✅ هذا هو السطر الحاسم الذي تم تصحيحه للتعامل مع القيم null بأمان
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // تم تعطيل التقليل والتقليل للموارد
            isShrinkResources = false
            // تم إضافة قسم proguardFiles مع ملف افتراضي
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// ✅ تم إضافة قسم الاعتماديات في نهاية الملف
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // استيراد Firebase BOM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    // إضافة الاعتمادية لـ Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    // إضافة الاعتمادية لـ Firebase Messaging (ضروري للإشعارات)
    implementation("com.google.firebase:firebase-messaging")
}

// ✅ تطبيق مكون Google Services في نهاية الملف
apply(plugin = "com.google.gms.google-services")