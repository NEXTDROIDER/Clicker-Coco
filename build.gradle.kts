plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "github.coconutgames.clicker"
    compileSdk = 36

    defaultConfig {
        applicationId = "github.coconutgames.clicker"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // ДОБАВЬ ЭТОТ БЛОК: Он явно указывает, где искать манифест
sourceSets {
        getByName("main") {
            // Раз манифест заработал так, добавим пути и для остального:
            manifest.srcFile("app/src/main/AndroidManifest.xml")
            res.srcDirs("app/src/main/res")
            java.srcDirs("app/src/main/java")
            assets.srcDirs("app/src/main/assets")
        }
       }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
}

