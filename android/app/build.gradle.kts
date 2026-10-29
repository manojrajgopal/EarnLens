plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ai.saasify.earnlens"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for scheduled notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "ai.saasify.earnlens"
        // Android 7.0+ (API 24): secure storage, biometrics and SQLite plugins require it.
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Debug keys keep `flutter run --release` working locally. Configure a
            // release keystore before publishing (see docs/PLATFORM_SUPPORT.md).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // AppCompat themes are required by the biometric prompt on Android 8 and below.
    implementation("androidx.appcompat:appcompat:1.7.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Every release build is also saved as build/app/outputs/flutter-apk/EarnLens.apk.
// Flutter's own app-release.apk is kept because the Flutter tool looks for it.
val releaseApk = layout.buildDirectory.file("outputs/apk/release/app-release.apk")
val namedApk = layout.buildDirectory.file("outputs/flutter-apk/EarnLens.apk")
tasks.matching { it.name == "assembleRelease" }.configureEach {
    doLast {
        val source = releaseApk.get().asFile
        if (source.exists()) source.copyTo(namedApk.get().asFile, overwrite = true)
    }
}
