#!/usr/bin/env bash
# 统一计算 versionName 和 versionCode，供 build/publish job 共用。
#
# 规则:
#   versionName = major.minor.run_number   (如 0.1.19)
#   versionCode = run_number + minor×10000 + major×1000000  (如 10019)
#
# 用法: source scripts/compute_version.sh
# 输出环境变量: VERSION_NAME, VERSION_CODE
# 依赖环境变量: RUN_NUMBER（由调用方从 github.run_number 注入）
set -euo pipefail

PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
MAJOR=$(echo "$PUBSPEC_VERSION" | cut -d '.' -f 1)
MINOR=$(echo "$PUBSPEC_VERSION" | cut -d '.' -f 2)
RUN_NUMBER="${RUN_NUMBER:?RUN_NUMBER must be set}"

VERSION_NAME="${MAJOR}.${MINOR}.${RUN_NUMBER}"
VERSION_CODE=$((RUN_NUMBER + MINOR * 10000 + MAJOR * 1000000))

echo "Computed: versionName=${VERSION_NAME} versionCode=${VERSION_CODE} (major=${MAJOR} minor=${MINOR} run_number=${RUN_NUMBER})"

export VERSION_NAME
export VERSION_CODE
