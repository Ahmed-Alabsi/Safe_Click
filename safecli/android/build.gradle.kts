// ✅ buildscript في أعلى الملف (بالإسم الصحيح)
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // ✅ التصحيح: kotlin-gradle-plugin وليس gradle-plugin
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")  // ✅ هذا هو الإسم الصحيح
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// ✅ باقي ملفك كما هو
allprojects {
    repositories {
        google()
        mavenCentral()
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