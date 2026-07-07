#!/usr/bin/env bash
# 给 `flutter create` 生成的 android/app/build.gradle 注入 release 签名配置。
#
# 背景：仓库只提交了自定义 AndroidManifest / MainActivity / file_paths，
# build.gradle 由 CI 里 `flutter create` 临时生成，默认 release 用 debug 签名，
# 而 debug 签名每次 CI 跑都会重新生成 → 签名不一致 → Android 拒绝覆盖安装，
# 自动更新通道跑不通。
#
# 本脚本读取已提交的 android/key.properties + android/app/release.jks，
# 在 build.gradle 的 android {} 块内注入 signingConfigs.release，
# 并把 release buildType 的签名指向它，保证每次 CI 产物签名一致。
set -euo pipefail

GRADLE="android/app/build.gradle"
[[ -f "$GRADLE" ]] || { echo "ERROR: $GRADLE not found（请先执行 flutter create）" >&2; exit 1; }
[[ -f "android/key.properties" ]] || { echo "ERROR: android/key.properties 缺失" >&2; exit 1; }
[[ -f "android/app/release.jks" ]] || { echo "ERROR: android/app/release.jks 缺失" >&2; exit 1; }

if grep -q "keystoreProperties" "$GRADLE"; then
  echo "signing config 已存在，跳过注入"
  exit 0
fi

python3 - <<'PY'
import io, re

path = "android/app/build.gradle"
src = io.open(path, encoding="utf-8").read()

block = (
    "\n"
    "    def keystoreProperties = new Properties()\n"
    "    def keystorePropertiesFile = rootProject.file('key.properties')\n"
    "    if (keystorePropertiesFile.exists()) {\n"
    "        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
    "    }\n"
    "    signingConfigs {\n"
    "        release {\n"
    "            keyAlias keystoreProperties['keyAlias']\n"
    "            keyPassword keystoreProperties['keyPassword']\n"
    "            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n"
    "            storePassword keystoreProperties['storePassword']\n"
    "        }\n"
    "    }\n"
)

# 在第一个 "android {" 之后插入 signingConfigs 块
src, n = re.subn(r'^android \{', 'android {' + block, src, count=1, flags=re.M)
assert n == 1, "未找到 'android {' 块"

# release buildType 指向 release 签名（替换默认的 debug 签名）
old = "signingConfig signingConfigs.debug"
new = "signingConfig signingConfigs.release"
assert old in src, f"未找到 '{old}'（Flutter 模板可能已变更，请检查 build.gradle）"
src = src.replace(old, new)

io.open(path, "w", encoding="utf-8").write(src)
print("已注入 release 签名配置")
PY
