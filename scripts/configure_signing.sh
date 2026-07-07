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

# release buildType 指向 release 签名
# 尝试替换默认的 debug 签名（旧版 Flutter 模板）
old = "signingConfig signingConfigs.debug"
new = "signingConfig signingConfigs.release"
if old in src:
    src = src.replace(old, new)
else:
    # 新版 Flutter 模板可能没有 signingConfig 行，直接在 buildTypes.release 块中添加
    # 使用花括号计数器定位正确的 buildTypes.release 块
    def find_buildtypes_release_block(src):
        lines = src.split('\n')
        in_buildtypes = False
        in_release = False
        depth = 0
        release_start = None
        release_end = None
        
        for i, line in enumerate(lines):
            if not in_buildtypes:
                if re.match(r'^\s*buildTypes\s*\{', line):
                    in_buildtypes = True
                    depth = line.count('{') - line.count('}')
            elif not in_release:
                depth += line.count('{') - line.count('}')
                if re.match(r'^\s*release\s*\{', line):
                    in_release = True
                    release_start = i
                    depth = line.count('{') - line.count('}')
            else:
                depth += line.count('{') - line.count('}')
                if depth == 0:
                    release_end = i
                    break
        
        return release_start, release_end
    
    release_start_line, release_end_line = find_buildtypes_release_block(src)
    
    if release_start_line is not None and release_end_line is not None:
        lines = src.split('\n')
        release_content = '\n'.join(lines[release_start_line:release_end_line+1])
        if "signingConfig" not in release_content:
            indent = '    '
            lines.insert(release_end_line, f'{indent}signingConfig signingConfigs.release')
            src = '\n'.join(lines)
            print("注意：未找到 'signingConfig signingConfigs.debug'，已直接在 release buildType 中添加签名配置")
        else:
            print("注意：release buildType 中已存在 signingConfig，跳过")
    else:
        print("警告：未找到 buildTypes.release 块，签名配置可能未正确注入")

io.open(path, "w", encoding="utf-8").write(src)
print("已注入 release 签名配置")
PY
