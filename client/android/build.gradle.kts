allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins hardcode a compileSdk older than the app's, and AGP 9 enforces
// the AAR metadata check that catches it: whisper_ggml pins compileSdk 34 while
// its own dependency ffmpeg_kit_flutter_new_min is built against 35 and refuses
// consumers below that. Raise any plugin below the app's compileSdk up to it.
// compileSdk only widens the API surface available at compile time — it does
// not change minSdk or targetSdk, so plugin runtime behaviour is unaffected.
// finalizeDsl, not afterEvaluate: the plugin's own build script assigns
// compileSdk while it evaluates, so anything set earlier is overwritten and
// AGP has already locked the DSL by the time a late afterEvaluate runs.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<
            com.android.build.api.variant.LibraryAndroidComponentsExtension
        >("androidComponents") {
            finalizeDsl { dsl ->
                val appCompileSdk = (
                    project(":app").extensions
                        .getByName("android") as com.android.build.api.dsl.ApplicationExtension
                ).compileSdk
                val current = dsl.compileSdk
                if (appCompileSdk != null &&
                    (current == null || current < appCompileSdk)
                ) {
                    dsl.compileSdk = appCompileSdk
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
