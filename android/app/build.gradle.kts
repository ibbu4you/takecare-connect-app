import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * The upload key, read from android/key.properties.
 *
 * That file and the keystore it points at are **not in the repository** and must
 * never be: anyone holding them can publish an update to this app under the
 * foundation's name. They are also irreplaceable — Play ties the listing to the
 * key's fingerprint, and losing it means the app can only ever be re-published
 * as a different listing that existing users have to find and install again.
 * Keep a copy somewhere that is backed up and is not this laptop.
 *
 * Absent, the release build falls back to the debug key. That still produces a
 * working APK for local testing, and Play rejects it on upload — which is the
 * right failure: loud, at the point of upload, rather than a release signed with
 * a key that changes every machine.
 */
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

val hasUploadKey = keystoreProperties.containsKey("storeFile")

android {
    namespace = "org.takecareinternational.takecare_connect"
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
        applicationId = "org.takecareinternational.takecare_connect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }

            // Shrinking is off deliberately.
            //
            // Flutter's Dart code is already compiled to a native library that
            // R8 cannot touch, so it only trims the Java/Kotlin shim and the
            // plugins — a small saving against a real risk of stripping
            // something a plugin reaches for by reflection, which fails at
            // runtime on a user's phone and never in testing.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
