plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Aplicar el complemento de Google Services
    

}

android {
    namespace = "com.example.neuromedex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // ✅ habilitar desugaring
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.neuromedex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    dependencies {
        implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

        implementation("com.google.firebase:firebase-analytics")
        implementation("com.google.firebase:firebase-auth")
        implementation("com.google.firebase:firebase-firestore")
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3") // ✅ ya estaba
        implementation ("org.tensorflow:tensorflow-lite:2.16.1")

   
        implementation ("org.tensorflow:tensorflow-lite-select-tf-ops:2.16.1")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}


flutter {
    source = "../.."
}
