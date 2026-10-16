import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing comes from android/key.properties (gitignored; see
// docs/PLAY_RELEASE.md for the format and how to generate the keystore).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

/**
 * Android needs a monotonically increasing integer, but pubspec carries a plain
 * major.minor.patch with no +build suffix — and with no suffix Flutter reports
 * versionCode 1 unconditionally, which Play would reject on the second upload.
 * Derive it instead, so bumping any component moves the code forward:
 *
 *     1.2.2 -> 10202      1.3.0 -> 10300      2.0.0 -> 20000
 *
 * This budgets two digits each to minor and patch; keep both under 100 or the
 * encoding overflows into the next component and ordering breaks.
 */
fun versionCodeFrom(name: String): Int {
    val parts = name.substringBefore('+').split('.')
    require(parts.size == 3) { "pubspec version must be major.minor.patch, got '$name'" }
    val (major, minor, patch) = parts.map {
        it.toIntOrNull() ?: throw GradleException("non-numeric version component in '$name'")
    }
    require(minor < 100 && patch < 100) { "minor and patch must be < 100, got '$name'" }
    return major * 10000 + minor * 100 + patch
}

android {
    namespace = "io.lab517.noo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.lab517.noo"
        // 28 is the floor, and voice memos are what set it: voice_audio's AAudio
        // backend calls AAudioStreamBuilder_setUsage, _setContentType and
        // _setInputPreset, which the NDK only declares from API 28. Below that
        // it would have to fall back to OpenSL ES — the code is there, but it
        // has never been built or run, so bumping the floor is the honest
        // choice over shipping an untested audio path to old devices.
        //
        // 24 was the previous floor, for SQLCipher/NDK and scoped storage;
        // both of those are still satisfied.
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = versionCodeFrom(flutter.versionName)
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // With no key.properties, fall back to debug keys so
            // `flutter run --release` still works on a dev machine. Play
            // uploads must be built with the release keystore present.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
