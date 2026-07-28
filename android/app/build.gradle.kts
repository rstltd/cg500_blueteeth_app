plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cg500_blueteeth_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.cg500_blueteeth_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            // AGP 8.x stores .so files uncompressed by default: better on-device
            // footprint and startup, at the cost of a much larger APK. That
            // trade-off assumes Play Store delivery, which re-compresses for
            // transport. This app ships the APK directly through its own in-app
            // OTA updater, and field crews may update over mobile data, so the
            // download size is what matters. Measured on Flutter 3.44.8:
            // 54.4 MB uncompressed vs 24.0 MB compressed, identical contents.
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
