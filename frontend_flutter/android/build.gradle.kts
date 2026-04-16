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

// Forcer Java 17 pour TOUS les projets y compris les dépendances de plugins (AGP 8.9.1 requiert Java 17)
// Configuration au niveau allprojects pour s'assurer que tout utilise Java 17
allprojects {
    // Configuration pour les tâches JavaCompile - force Java 17 (s'applique à toutes les tâches y compris celles des plugins)
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        options.compilerArgs.add("-Xlint:-options")
    }

    // Configuration pour les tâches KotlinCompile - force JVM target 17
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

// Configuration supplémentaire après évaluation de tous les projets
gradle.projectsEvaluated {
    allprojects {
        // S'assurer que les tâches Android utilisent Java 17
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        
        // Configuration Android SDK pour les plugins Flutter (fallback)
        try {
            if (project.plugins.hasPlugin("com.android.library")) {
                val android = project.extensions.findByName("android")
                if (android is com.android.build.gradle.LibraryExtension) {
                    val libExt = android as com.android.build.gradle.LibraryExtension
                    // Forcer compileSdk à 36 pour tous les plugins
                    try {
                        libExt.compileSdk = 36
                    } catch (e: Exception) {
                        // Ignorer si on ne peut pas accéder à compileSdk
                    }
                    // Forcer Java 17 pour la compilation
                    libExt.compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                    // S'assurer que les dépendances Android sont disponibles
                    libExt.defaultConfig {
                        // Ne rien faire, juste s'assurer que defaultConfig existe
                    }
                }
            }
        } catch (e: Exception) {
            // Ignorer si le projet n'a pas d'extension Android
        }
    }
}

// Configuration également au niveau root pour les tâches du projet root
tasks.withType<JavaCompile>().configureEach {
    sourceCompatibility = JavaVersion.VERSION_17.toString()
    targetCompatibility = JavaVersion.VERSION_17.toString()
    options.compilerArgs.add("-Xlint:-options")
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "17"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
