buildscript {
    repositories {
        google()
        mavenCentral()
        // Miroirs alternatifs en fallback
        maven {
            url = uri("https://repo1.maven.org/maven2")
            name = "Maven Central Alternative"
        }
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
        // Forcer une version compatible de Gradle pour tous les plugins
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        // Repositories principaux
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx\\..*")
            }
        }
        mavenCentral {
            content {
                includeGroupByRegex("org\\.videolan.*")
                includeGroupByRegex(".*")
            }
        }
        
        // Miroirs alternatifs en fallback
        maven {
            url = uri("https://repo1.maven.org/maven2")
            name = "Maven Central Alternative"
            isAllowInsecureProtocol = false
        }
    }
    
    // Forcer la version de Gradle pour tous les sous-projets
    afterEvaluate {
        buildscript {
            repositories {
                google()
                mavenCentral()
                maven {
                    url = uri("https://repo1.maven.org/maven2")
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
