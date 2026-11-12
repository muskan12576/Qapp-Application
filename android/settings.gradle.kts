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
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// zego_zim 3.3.0+1 still calls jcenter() (removed in Gradle 9) and pins AGP 4.1.0.
// Rewrite that cached build file before Gradle evaluates the plugin. Safe to re-run
// after a fresh `flutter pub get`, which restores the original file.
run {
    val zegoProject = runCatching { project(":zego_zim") }.getOrNull() ?: return@run
    val zegoBuild = zegoProject.projectDir.resolve("build.gradle")
    if (!zegoBuild.isFile) return@run
    val original = zegoBuild.readText().replace("\r\n", "\n")
    if (!original.contains("jcenter()") && !original.contains("com.android.tools.build:gradle:4.1.0")) {
        return@run
    }
    val patched =
        original
            .replace("jcenter()", "mavenCentral()")
            .replace(
                "classpath 'com.android.tools.build:gradle:4.1.0'",
                "classpath 'com.android.tools.build:gradle:8.5.2'",
            )
            .replace(
                "    if (project.android.hasProperty(\"namespace\")) {\n        namespace 'im.zego.zim_flutter'\n    }",
                "    namespace 'im.zego.zim_flutter'",
            )
            .replace("compileSdkVersion 31", "compileSdkVersion flutter.compileSdkVersion")
            .replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
            .replace("minSdkVersion 16", "minSdkVersion 21")
    if (patched != original) {
        zegoBuild.writeText(patched)
        println("Patched zego_zim Android build for Gradle 9.")
    }
}
