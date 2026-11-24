allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.zego.im/maven") }
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

gradle.projectsEvaluated {
    subprojects {
        tasks.matching { it.name.startsWith("sync") && it.name.endsWith("LibJars") }.configureEach {
            val variant = name.removePrefix("sync").removeSuffix("LibJars")
            dependsOn("merge${variant}JavaResource")
        }
    }
}

allprojects {
    tasks.matching { it.name.startsWith("preBuild") }.configureEach {
        doLast {
            layout.buildDirectory.dir("intermediates/external_file_lib_dex_archives/debug/desugarDebugFileDependencies").get().asFile.mkdirs()
            layout.buildDirectory.dir("intermediates/merged_java_res/debug/mergeDebugJavaResource").get().asFile.mkdirs()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
