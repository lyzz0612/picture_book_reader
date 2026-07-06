#!/usr/bin/env bash
# 生成版本清单 manifest.json
#
# 用法: ./scripts/generate_manifest.sh <version> <build_number>
#
# 读取环境变量:
#   CDN_BASE              CDN 根地址（完整指定，含项目前缀，不带末尾斜杠）
#                         如 https://cdn.example.com/picture_book_reader
#                         需与 workflow 中 R2_PREFIX 上传路径保持一致
#   RELEASE_NOTES         更新说明（可选）
#   MIN_REQUIRED_VERSION  最低强制更新版本（可选，默认 0.0.1）
#
# 依赖: 当前目录存在已重命名的 app-release-<version>-build<build>.apk
set -euo pipefail

APP_VERSION="${1:?usage: generate_manifest.sh <version> <build_number>}"
BUILD_NUMBER="${2:?usage: generate_manifest.sh <version> <build_number>}"

# CDN_BASE 由 secret 完整指定，仅去掉末尾斜杠避免双斜杠
CDN_BASE="${CDN_BASE:-https://cdn.example.com/picture_book_reader}"
CDN_BASE="${CDN_BASE%/}"
RELEASE_NOTES="${RELEASE_NOTES:-新版本已发布}"
MIN_REQUIRED_VERSION="${MIN_REQUIRED_VERSION:-0.0.1}"

APK_NAME="app-release-${APP_VERSION}-build${BUILD_NUMBER}.apk"
APK_PATH="${APK_NAME}"

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: APK not found: $APK_PATH" >&2
  exit 1
fi

# sha256 & size（兼容 GNU stat 与 BSD stat）
SHA256=$(sha256sum "$APK_PATH" | awk '{print $1}')
if stat --version >/dev/null 2>&1; then
  SIZE=$(stat -c %s "$APK_PATH")
else
  SIZE=$(stat -f %z "$APK_PATH")
fi

# 转义 release notes 中的双引号与反斜杠，避免破坏 JSON
ESC_NOTES=$(printf '%s' "$RELEASE_NOTES" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > manifest.json <<EOF
{
  "latestVersion": "${APP_VERSION}",
  "latestBuild": ${BUILD_NUMBER},
  "platforms": {
    "android": {
      "url": "${CDN_BASE}/android/${APK_NAME}",
      "sha256": "${SHA256}",
      "sizeBytes": ${SIZE}
    }
  },
  "releaseNotes": "${ESC_NOTES}",
  "minRequiredVersion": "${MIN_REQUIRED_VERSION}"
}
EOF

echo "Generated manifest.json:"
cat manifest.json
