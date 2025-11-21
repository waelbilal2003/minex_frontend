import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.Minex"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // ✅✅ توحيد إصدار Java لكل من Java و Kotlin
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.Minex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    signingConfigs {
    create("release") {
        println("🔑 Configuring release signing from GitHub Secrets...")

        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
        storeFile = file(System.getenv("STORE_FILE") ?: "minex.jks")
        storePassword = System.getenv("STORE_PASSWORD")

        if (keyAlias == null) {
            throw GradleException("❌ KEY_ALIAS secret not found in GitHub Actions.")
        }
        if (keyPassword == null) {
            throw GradleException("❌ KEY_PASSWORD secret not found in GitHub Actions.")
        }
        if (storePassword == null) {
            throw GradleException("❌ STORE_PASSWORD secret not found in GitHub Actions.")
        }

        println("✅ Release signing configured successfully from GitHub Secrets.")
    }
}
    
   buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
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
