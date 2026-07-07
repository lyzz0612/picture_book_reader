#!/usr/bin/env bash
# 直接生成 android/app/build.gradle，注入固定 release 签名配置。
#
# 背景：仓库只提交了自定义 AndroidManifest / MainActivity / file_paths，
# build.gradle 由 CI 里 `flutter create` 临时生成。不同 Flutter 版本的模板
# 格式不一致，用正则/文本解析注入 signingConfig 极易走错分支，导致 release
# 构建静默落到 debug 签名 → 每次 CI 签名不一致 → Android 拒绝覆盖安装。
#
# 因此改为：直接覆盖 build.gradle，确保 signingConfigs.release 始终生效。
# 读取已提交的 android/key.properties + android/app/release.jks 作为固定签名。
set -euo pipefail

GRADLE="android/app/build.gradle"
[[ -f "android/key.properties" ]] || { echo "ERROR: android/key.properties 缺失" >&2; exit 1; }
[[ -f "android/app/release.jks" ]] || { echo "ERROR: android/app/release.jks 缺失" >&2; exit 1; }

cat > "$GRADLE" <<'GRADLE_EOF'
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localProperties.load(new FileInputStream(localPropertiesFile))
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode') ?: '1'
def flutterVersionName = localProperties.getProperty('flutter.versionName') ?: '1.0'

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace "com.example.picture_book_reader"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.example.picture_book_reader"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}

flutter {
    source '../..'
}
GRADLE_EOF

# 强制校验：确保 release 签名配置已写入
if ! grep -q "signingConfig signingConfigs.release" "$GRADLE"; then
  echo "ERROR: 写入后未在 $GRADLE 找到 'signingConfig signingConfigs.release'" >&2
  exit 1
fi
echo "OK: build.gradle 已生成，release 签名配置已写入"
