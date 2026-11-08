pluginManagement {
    val flutterSdkPath = run {
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
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri(findRustlsPlatformVerifierProject())
            metadataSources.artifact()
        }
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

include(":app")

fun findRustlsPlatformVerifierProject(): String {
    // Gradle runs from android/; the Flutter project root is its parent.
    val projectRoot = rootDir.parentFile
    val cargoBin = System.getenv("CARGO") ?: "cargo"

    val dependencyText = providers.exec {
        workingDir = projectRoot
        commandLine(cargoBin, "metadata", "--format-version", "1",
            "--manifest-path", "rust/cloudflare-quick-tunnel-rs/Cargo.toml")
    }.standardOutput.asText.get()

    val manifestPathRegex = """"name":"rustls-platform-verifier-android".*?"manifest_path":"([^"]+)"""".toRegex()
    val match = manifestPathRegex.find(dependencyText)
    requireNotNull(match) { "rustls-platform-verifier-android not found" }
    val manifestPath = File(match.groupValues[1])
    return File(manifestPath.parentFile, "maven").absolutePath
}
