// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.skillseed_app"

    // Keep Flutter-managed compile sdk; fine to leave as-is
    compileSdk = flutter.compileSdkVersion

    // NDK required by your plugins
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.skillseed_app"

        // --- FIX: bump minSdk for Firebase plugins ---
        minSdk = 23

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Align Java/Kotlin (prevents "Inconsistent JVM-target" errors)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Desugaring (needed by some libs)
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Use proper release signing when you’re ready
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
