// Root build.gradle.kts — Flutter + Firebase (Kotlin DSL)

// ⚠️ Do NOT redeclare flutter plugin here — Flutter manages it automatically

plugins {
    id("com.android.application") version "8.7.3" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
