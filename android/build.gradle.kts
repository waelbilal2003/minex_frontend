buildscript {
    // ⭐ ⭐ ⭐ الطريقة الصحيحة لتعريف المتغير ⭐ ⭐ ⭐
    // 1. تعريف كـ `ext` property
    // ext.kotlin_version = "2.1.0"

    // أو 2. تعريف كـ `extra` property (الطريقة المفضلة في Kotlin DSL)
    // extra["kotlin_version"] = "2.1.0" // ⭐ ⭐ ⭐ هذا هو السطر المهم ⭐ ⭐ ⭐

    // أو 3. تعريف كـ متغير محلي داخل block
    val kotlin_version = "2.1.0" // ⭐ ⭐ ⭐ هذا هو السطر المهم ⭐ ⭐ ⭐

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.9.1")
        // ⭐ ⭐ ⭐ استخدام المتغير بعد تعريفه ⭐ ⭐ ⭐
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version") // ⭐ ⭐ ⭐ الآن $kotlin_version معرف ⭐ ⭐ ⭐
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ⭐ ⭐ ⭐ تأكد أن قسم plugins هذا في الملف الخاطئ ⭐ ⭐ ⭐
// ⭐ ⭐ ⭐ يجب أن يكون في android/app/build.gradle.kts ⭐ ⭐ ⭐
//plugins {
//    id("com.android.application")
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//    id("dev.flutter.flutter-gradle-plugin")
//    id("com.google.gms.google-services")
//}