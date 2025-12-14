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
    id("com.android.application") version "8.9.1" apply false
    id("com.google.gms.google-services") version("4.3.15") apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()

        // JitPack (for kotlin-events and other dependencies)
        maven { url = uri("https://jitpack.io") }

        // -----------------------------------------------------------
        // Spotify Android SDK Repository
        // -----------------------------------------------------------
        maven { url = uri("https://raw.githubusercontent.com/spotify/android-sdk/master/mvn-repo/") }

        // Flutter Storage (Required for plugins)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

include(":app")

// Include Spotify SDK's spotify-app-remote module
val userHome = System.getProperty("user.home")
val pubCacheGitPath = File(userHome, ".pub-cache/git")
val spotifySdkPath = pubCacheGitPath.listFiles()
    ?.find { it.name.startsWith("spotify_sdk-") }

if (spotifySdkPath != null) {
    val spotifyAppRemotePath = File(spotifySdkPath, "android/spotify-app-remote")
    if (spotifyAppRemotePath.exists()) {
        include(":spotify-app-remote")
        project(":spotify-app-remote").projectDir = spotifyAppRemotePath
    }
}