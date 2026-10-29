import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing secrets live outside the repository; see README "Release signing".
val releaseSigningProperties =
    Properties().apply {
        val file = rootProject.file("key.properties")
        if (file.exists()) file.inputStream().use(::load)
    }

android {
    namespace = "com.paulcarouge.komit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time APIs on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Differs from the original app's id so both can be installed while data is migrated.
        applicationId = "com.paulcarouge.komit.next"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseSigningProperties.getProperty("storeFile")?.let(::file)
            storePassword = releaseSigningProperties.getProperty("storePassword")
            keyAlias = releaseSigningProperties.getProperty("keyAlias")
            keyPassword = releaseSigningProperties.getProperty("keyPassword")
        }
    }

    testOptions {
        // TestNG (Apache-2.0) rather than JUnit (EPL), to keep every dependency permissively licensed.
        unitTests.all { it.useTestNG() }
    }

    buildTypes {
        release {
            // In-app updates only install over an APK signed with the same key, so never fall back to debug keys.
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    testImplementation("org.testng:testng:7.10.2")
}
