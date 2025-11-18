allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure all projects to suppress only obsolete warnings while keeping deprecation visible
allprojects {
    tasks.withType<JavaCompile> {
        options.compilerArgs.addAll(listOf(
            "-Xlint:-options",
            "-Xlint:-unchecked"
        ))
        // Keep deprecation warnings visible
        options.isWarnings = true
        options.isDeprecation = true
    }
    
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        kotlinOptions {
            allWarningsAsErrors = false
            // Don't suppress warnings - let deprecation warnings show
            suppressWarnings = false
            freeCompilerArgs += listOf(
                "-Xno-call-assertions",
                "-Xno-receiver-assertions", 
                "-Xno-param-assertions",
                "-Xsuppress-deprecated-jvm-target-warning"
            )
        }
        // Disable incremental compilation to avoid cache corruption
        incremental = false
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
