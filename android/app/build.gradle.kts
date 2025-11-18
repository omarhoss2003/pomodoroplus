plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pomodoroplus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        allWarningsAsErrors = false
        // Keep deprecation warnings visible
        suppressWarnings = false
        freeCompilerArgs += listOf(
            "-Xno-call-assertions",
            "-Xno-receiver-assertions",
            "-Xno-param-assertions",
            "-Xsuppress-deprecated-jvm-target-warning"
        )
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pomodoroplus"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
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

    lint {
        disable += listOf(
            "ObsoleteLintCustomCheck",
            "NewApi",
            "OldTargetApi",
            "GradleDependency",
            "ExpiredTargetSdkVersion"
        )
        // Keep deprecation warnings visible, only disable critical errors
        checkReleaseBuilds = false
        abortOnError = false
        quiet = false
        ignoreWarnings = false
        warningsAsErrors = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
