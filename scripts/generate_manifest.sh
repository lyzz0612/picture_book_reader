#!/usr/bin/env bash
# 生成版本清单 manifest.json
#
# 用法: ./scripts/generate_manifest.sh <version_name> <version_code>
#
# 参数:
#   version_name  versionName，如 "0.1.16"
#   version_code  versionCode，整数，如 10016
#
# 读取环境变量:
#   CDN_BASE              CDN 根地址（完整指定，含项目前缀，不带末尾斜杠）
#                         如 https://cdn.example.com/picture_book_reader
#                         需与 workflow 中 R2_PREFIX 上传路径保持一致
#   RELEASE_NOTES         更新说明（可选）
#   MIN_REQUIRED_VERSION  最低强制更新版本（可选，默认 0.0.1，versionName 格式）
#
# 依赖: 当前目录存在固定文件名的 app-release.apk
#
# 设计：APK 文件名固定为 app-release.apk，每次发布覆盖 R2 同一对象，
# 避免历史版本堆积。下载 URL 追加 ?v=<version_name> 查询串，
# Cloudflare 按"完整 URL（含查询串）"缓存，新版查询串即缓存未命中 → 拉取最新对象，
# 旧版查询串各自缓存互不干扰，从而在固定文件名下保证 CDN 缓存正确性。
set -euo pipefail

VERSION_NAME="${1:?usage: generate_manifest.sh <version_name> <version_code>}"
VERSION_CODE="${2:?usage: generate_manifest.sh <version_name> <version_code>}"

# CDN_BASE 由 secret 完整指定，仅去掉末尾斜杠避免双斜杠
CDN_BASE="${CDN_BASE:-https://cdn.example.com/picture_book_reader}"
CDN_BASE="${CDN_BASE%/}"
RELEASE_NOTES="${RELEASE_NOTES:-新版本已发布}"
MIN_REQUIRED_VERSION="${MIN_REQUIRED_VERSION:-0.0.1}"

# 固定文件名（CI 上传到 R2 的对象 key 也固定为 android/app-release.apk）
APK_NAME="app-release.apk"
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

# 下载 URL：固定路径 + 查询串区分版本（CDN 缓存键 = 完整 URL）
DOWNLOAD_URL="${CDN_BASE}/android/${APK_NAME}?v=${VERSION_NAME}"

cat > manifest.json <<EOF
{
  "latestVersion": "${VERSION_NAME}",
  "latestVersionCode": ${VERSION_CODE},
  "platforms": {
    "android": {
      "url": "${DOWNLOAD_URL}",
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
