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
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")

// Patch plugins for Gradle 9 and Android compileSdk compatibility
run {
    val pluginList = mutableSetOf(":zego_zim", ":zego_express_engine", ":flutter_ringtone_player")
    rootProject.children.forEach { pluginList.add(it.path) }
    pluginList.forEach { pluginName ->
        if (pluginName == ":app") return@forEach
        val proj = runCatching { project(pluginName) }.getOrNull() ?: return@forEach
        val buildFile = proj.projectDir.resolve("build.gradle")
        if (!buildFile.isFile) return@forEach
        val original = buildFile.readText().replace("\r\n", "\n")
        var patched = original
        if (patched.contains("jcenter()")) {
            patched = patched.replace("jcenter()", "mavenCentral()")
        }
        if (patched.contains("com.android.tools.build:gradle:4.1.0")) {
            patched = patched.replace(
                "classpath 'com.android.tools.build:gradle:4.1.0'",
                "classpath 'com.android.tools.build:gradle:8.5.2'",
            )
        }
        patched = patched.replace(Regex("""compileSdkVersion\s+(2[89]|3[0123])"""), "compileSdkVersion 35")
        patched = patched.replace(Regex("""compileSdk\s*=\s*(2[89]|3[0123])"""), "compileSdk = 35")
        if (patched.contains("minSdkVersion 16")) {
            patched = patched.replace("minSdkVersion 16", "minSdkVersion 21")
        }
        if (patched.contains("JavaVersion.VERSION_1_8")) {
            patched = patched.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
        }
        if (patched != original) {
            buildFile.writeText(patched)
            println("Patched $pluginName Android build for Gradle / compileSdk 35.")
        }
    }
}
