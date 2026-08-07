plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase (FCM) nur einbinden, wenn eine google-services.json vorliegt. So
// bleibt der Android-Build ohne Firebase-Konfiguration weiterhin baubar; ohne
// die Datei ist der Push schlicht inaktiv.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "de.lukas.multiapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Von flutter_local_notifications fuer exakte, zeitzonenbasierte
        // Erinnerungen auf aelteren Android-Versionen benoetigt.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "de.lukas.multiapp"
        // minSdk 21+ ist Voraussetzung fuer flutter_local_notifications.
        minSdk = maxOf(flutter.minSdkVersion, 23)
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
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // FileProvider: gibt die heruntergeladene APK an den System-Installer
    // weiter (eigener Update-Kanal in MainActivity).
    implementation("androidx.core:core-ktx:1.13.1")
}
