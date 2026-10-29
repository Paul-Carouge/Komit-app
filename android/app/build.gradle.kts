import com.android.build.api.artifact.SingleArtifact
import java.util.Properties
import javax.xml.parsers.DocumentBuilderFactory

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

/**
 * Every permission the release APK may request. A new one, often pulled in by a plugin's
 * manifest, fails the release build until it is reviewed here and explained on the in-app
 * privacy screen.
 */
fun releaseManifestAllowedPermissions(applicationId: String): Set<String> =
    setOf(
        "android.permission.INTERNET",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.RECEIVE_BOOT_COMPLETED",
        "android.permission.REQUEST_INSTALL_PACKAGES",
        "android.permission.VIBRATE",
        "android.permission.USE_BIOMETRIC",
        // Declared by androidx.core so that only this app can send its dynamic broadcasts.
        "$applicationId.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION",
    )

/** Fails when the merged release manifest requests an unlisted permission or lost its backup rules. */
abstract class VerifyReleaseManifestTask : DefaultTask() {
    @get:InputFile
    abstract val mergedManifest: RegularFileProperty

    @get:Input
    abstract val allowedPermissions: SetProperty<String>

    @TaskAction
    fun verify() {
        val androidNamespace = "http://schemas.android.com/apk/res/android"
        val document =
            DocumentBuilderFactory
                .newInstance()
                .apply { isNamespaceAware = true }
                .newDocumentBuilder()
                .parse(mergedManifest.get().asFile)
        val requestedPermissions =
            listOf("uses-permission", "uses-permission-sdk-23").flatMap { tagName ->
                val nodes = document.getElementsByTagName(tagName)
                (0 until nodes.length).map { index ->
                    (nodes.item(index) as org.w3c.dom.Element).getAttributeNS(androidNamespace, "name")
                }
            }
        val unexpectedPermissions = requestedPermissions.toSet() - allowedPermissions.get()
        if (unexpectedPermissions.isNotEmpty()) {
            throw GradleException(
                "The release manifest requests permissions outside the allowlist: $unexpectedPermissions. " +
                    "Review them, then add them to releaseManifestAllowedPermissions in app/build.gradle.kts.",
            )
        }
        val application = document.getElementsByTagName("application").item(0) as org.w3c.dom.Element
        for (backupAttribute in listOf("allowBackup", "fullBackupContent", "dataExtractionRules")) {
            if (application.getAttributeNS(androidNamespace, backupAttribute).isEmpty()) {
                throw GradleException("The release manifest lost android:$backupAttribute; see docs/adr/0005.")
            }
        }
    }
}

androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        val verifyTask =
            tasks.register<VerifyReleaseManifestTask>("verifyReleaseManifest") {
                mergedManifest.set(variant.artifacts.get(SingleArtifact.MERGED_MANIFEST))
                allowedPermissions.set(variant.applicationId.map(::releaseManifestAllowedPermissions))
            }
        tasks.matching { it.name in setOf("assembleRelease", "bundleRelease", "check") }.configureEach {
            dependsOn(verifyTask)
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
    // Android's org.json is a stub on the JVM; this is the reference implementation (public domain).
    testImplementation("org.json:json:20240303")
}
