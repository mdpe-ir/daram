pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // The Flutter SDK may be mounted read-only in sandboxed environments.
    // `.tool/flutter_gradle` is a writable copy used only when present.
    val writableCopy = file("../.tool/flutter_gradle")
    val gradlePluginBuild =
        if (writableCopy.exists()) writableCopy else file("$flutterSdkPath/packages/flutter_tools/gradle")
    includeBuild(gradlePluginBuild.absolutePath)

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
