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
        // Miroirs alternatifs en fallback
        maven {
            url = uri("https://repo1.maven.org/maven2")
            name = "Maven Central Alternative"
        }
    }
    
    resolutionStrategy {
        eachPlugin {
            // Forcer la version de Gradle pour les plugins Android
            if (requested.id.id == "com.android.application" || 
                requested.id.id == "com.android.library") {
                if (requested.version == null || requested.version == "8.7.0") {
                    useVersion("8.9.1")
                }
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
