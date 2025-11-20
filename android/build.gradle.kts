buildscript {
    // ⭐ ⭐ ⭐ تعريف المتغير في buildscript ⭐ ⭐ ⭐
    // هذا هو المكان المناسب لتعريف kotlin_version في Kotlin DSL
    var kotlin_version: String by extra // أو عيّن القيمة مباشرة: var kotlin_version: String by extra("2.1.0")

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // ⭐ ⭐ ⭐ استخدام صيغة Kotlin DSL ⭐ ⭐ ⭐
        classpath("com.android.tools.build:gradle:8.9.1") // <-- ✅ استخدم classpath("...")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version") // <-- ✅ استخدم classpath("...")
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

// ⭐ ⭐ ⭐ تأكد من أن قسم plugins هذا في الملف الخاطئ ⭐ ⭐ ⭐
// ⭐ ⭐ ⭐ يجب أن يكون في android/app/build.gradle.kts ⭐ ⭐ ⭐
//plugins {
//    id("com.android.application")
//    id("kotlin-android")
//    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//    id("dev.flutter.flutter-gradle-plugin")
//    id("com.google.gms.google-services")
//}