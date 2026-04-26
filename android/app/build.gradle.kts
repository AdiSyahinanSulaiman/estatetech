plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.estatetech.app.estatetech"
    compileSdk = 36 // Updated to 36 for modern multimedia support

    compileOptions {
        // THIS IS THE CRITICAL FIX FOR THE NOTIFICATION ERROR
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.estatetech.app.estatetech"

        // API 24 is required for modern WebViews and Storage
        minSdk = 24
        targetSdk = 36

        // Required because Firebase makes the app very large
        multiDexEnabled = true

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // THIS LINE IS REQUIRED TO SUPPORT MODERN JAVA FEATURES ON OLDER PHONES
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}