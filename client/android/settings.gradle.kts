pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 9 defaults to built-in Kotlin, which cannot coexist with plugins that
    // apply the external Kotlin plugin. android.builtInKotlin is therefore set
    // to false in gradle.properties: ffmpeg_kit_flutter_new_min and pasteboard
    // still apply the external one, which AGP 9 only warns about while built-in
    // Kotlin is off.
    //
    // This is also why file_picker must stay on 12.x: the 11.x line skipped the
    // external Kotlin plugin whenever AGP was 9+, assuming built-in Kotlin was
    // on, so its own Kotlin never compiled. 12.x reads android.builtInKotlin
    // and applies the plugin when it is false.
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
