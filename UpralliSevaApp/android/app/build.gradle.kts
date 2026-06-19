import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ಬಿಡುಗಡೆ ಸಹಿ (release signing) — android/key.properties ಇದ್ದರೆ ಬಳಸುತ್ತದೆ.
// ಇದು ಹಂಚಿದ APK ಗಳು ಯಾವಾಗಲೂ ಒಂದೇ ಕೀ ಯಿಂದ ಸಹಿಯಾಗಿ "ಅಪ್‌ಡೇಟ್" ಆಗಿ ಸ್ಥಾಪನೆಯಾಗಲು ಅಗತ್ಯ.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.upralliseva.upralliseva_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Firebase google-services.json ಗೆ ಹೊಂದುವಂತೆ (package_name = com.upralliseva.app)
        applicationId = "com.upralliseva.app"
        // firebase_auth ಗೆ minSdk >= 23 ಬೇಕು
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties ಇದ್ದರೆ release ಕೀ; ಇಲ್ಲದಿದ್ದರೆ debug (ಆ್ಯಪ್ ಚಲಿಸಲಿ ಎಂದು).
            signingConfig = if (keystorePropertiesFile.exists())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
