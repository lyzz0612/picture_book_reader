# 绘本阅读 App · 技术原型与 MVP 设计文档

> 创建日期：2026-07-03
> 仓库：lyzz0612/picture_book_reader
> 技术栈：Flutter
> 目标平台：**Android 优先，iOS 不在 MVP 考虑范围内**（自动更新、CI/CD、签名等流程仅针对 Android，iOS 后续如需支持需单独规划）

---

## 1. 产品概述

一款面向家长的绘本阅读工具，支持两种阅读模式：

- **文字版**：家长夜间讲故事场景。纯文字故事列表，家长照着屏幕念给小朋友听。
- **绘本版**：标准图文绘本阅读。一张图片对应多段文字，在同图内逐段切换文字，全部念完才翻到下一张图。

MVP 阶段内容全部内置，无后端服务，纯客户端运行。

---

## 2. MVP 范围

| 维度 | MVP | 后续 |
|------|-----|------|
| 模式 | 文字版 + 绘本版 | — |
| 内容来源 | 内置（打包进 App） | 在线下载、用户上传 |
| 后端服务 | 无 | 账号体系、云同步 |
| 自动更新 | 有（框架阶段即实现） | — |
| 交互动画 | 基础翻页 + 文字切换 | 语音伴读、交互式元素 |
| 平台 | **Android**（手机 + 平板） | iOS（暂不考虑，后续单独规划） |

---

## 3. 实施阶段

开发按以下顺序推进，每个阶段都可独立验证：

```
阶段 1：项目骨架
  └─ Flutter 项目初始化、目录结构、双模式入口路由

阶段 2：自动更新系统
  └─ GitLab CI 打包 → Cloudflare CDN 分发 → App 检测下载安装

阶段 3：MVP 功能
  ├─ 文字版：故事列表 → 纯文字阅读
  └─ 绘本版：一图多文阅读器
```

阶段 2 必须在阶段 3 之前完成。自动更新通道跑通后，后续所有功能迭代都能推送到设备上验证。

---

## 4. 数据结构设计

### 4.1 核心模型关系

```
Book（绘本）
  └─ Page（页面/张图）
       └─ TextSegment（文字段）
```

一本绘本包含多张页面（每张对应一张图片），每张页面包含多段文字。阅读时在同一页面内逐段切换文字，全部文字走完才翻到下一张页面。

### 4.2 数据定义

```dart
/// 绘本
class Book {
  final String id;                    // 唯一标识
  final String title;                 // 绘本标题
  final String coverPath;             // 封面图片路径（assets 内相对路径）
  final BookMode mode;                // 模式：textOnly / pictureBook
  final List<Page> pages;             // 页面列表
  final int? estimatedMinutes;        // 预计阅读时长（分钟）
}

/// 模式枚举
enum BookMode {
  textOnly,     // 文字版
  pictureBook,  // 绘本版
}

/// 页面（绘本版：一张图 + 多段文字；文字版：纯多段文字）
class Page {
  final String id;
  final String? imagePath;            // 图片路径（文字版为 null）
  final List<TextSegment> segments;   // 文字段列表
}

/// 文字段
class TextSegment {
  final String id;
  final String text;                  // 文字内容
  final int? durationHint;            // 预计朗读时长（秒），用于自动切换提示
}
```

### 4.3 内置内容格式

内置绘本以 JSON 配置 + 图片资源形式打包进 App：

```
assets/
  books/
    book_001/
      cover.png
      meta.json          // Book + Page + TextSegment 的序列化
      page_01.png
      page_02.png
      ...
    book_002/
      ...
```

`meta.json` 示例：

```json
{
  "id": "book_001",
  "title": "小兔子的冒险",
  "coverPath": "books/book_001/cover.png",
  "mode": "pictureBook",
  "estimatedMinutes": 5,
  "pages": [
    {
      "id": "p1",
      "imagePath": "books/book_001/page_01.png",
      "segments": [
        { "id": "s1", "text": "从前有一只小兔子，它住在一个温暖的洞穴里。" },
        { "id": "s2", "text": "有一天，它决定去看看外面的世界。" },
        { "id": "s3", "text": "于是它蹦蹦跳跳地出发了。" }
      ]
    },
    {
      "id": "p2",
      "imagePath": "books/book_001/page_02.png",
      "segments": [
        { "id": "s4", "text": "小兔子来到了一条小河边。" },
        { "id": "s5", "text": "它看到水里有一条金色的小鱼。" }
      ]
    }
  ]
}
```

### 4.4 书架索引

所有内置绘本在一个索引文件中注册：

```json
// assets/books/index.json
{
  "books": [
    { "id": "book_001", "title": "小兔子的冒险", "mode": "pictureBook", "metaPath": "books/book_001/meta.json" },
    { "id": "book_002", "title": "睡前故事集", "mode": "textOnly", "metaPath": "books/book_002/meta.json" }
  ]
}
```

App 启动时读取 `index.json`，构建书架列表。用户点进某本绘本时再加载对应 `meta.json`。

---

## 5. 核心交互设计

### 5.1 双模式入口

App 启动后进入模式选择页，两个入口卡片：

```
┌─────────────────────────────┐
│        绘本阅读              │
│                             │
│   ┌──────────┐ ┌──────────┐ │
│   │  文字版   │ │  绘本版   │ │
│   │ 家长念故事 │ │ 图文阅读  │ │
│   └──────────┘ └──────────┘ │
└─────────────────────────────┘
```

选择模式后进入对应模式的书架列表。两种模式共用同一套 `Book` 数据结构，通过 `BookMode` 字段区分。

### 5.2 绘本版阅读状态机

绘本版的核心是"一图多文"——同一张图内切换多段文字，全部念完才翻页。

```
                    ┌──────────────────────────────────────┐
                    │          绘本版阅读状态机              │
                    └──────────────────────────────────────┘

  ┌─────────┐
  │ 页面加载  │
  └────┬────┘
       ▼
  ┌─────────────┐  切换下一段   ┌───────────────┐
  │ 显示当前图片 │ ──────────▶ │ 显示第 N 段文字 │
  │ + 第 1 段文字│              │ (同图，高亮当前) │
  └─────────────┘              └───────┬───────┘
       ▲                               │
       │                               │ 还有下一段？
       │ No                    ┌───────┴───────┐
       │                       ▼ Yes            ▼ No
       │              ┌──────────────┐  ┌──────────────┐
       │              │ 切换到下一段   │  │ 当前页文字念完 │
       │              │ (同图内)      │  │ → 翻到下一张图 │
       │              └──────────────┘  └──────┬───────┘
       │                                       │
       │                              还有下一张图？
       │                              ┌───────┴───────┐
       │                              ▼ Yes           ▼ No
       │                     ┌──────────────┐  ┌──────────┐
       └─────────────────────│ 加载下一张图   │  │ 阅读完成  │
                             │ + 第 1 段文字 │  │ → 返回书架 │
                             └──────────────┘  └──────────┘
```

**状态跟踪**：阅读器维护两个索引：
- `pageIndex`：当前页面索引（对应第几张图）
- `segmentIndex`：当前文字段索引（当前图内第几段文字）

**交互操作**：
- 点击屏幕右侧 / 右滑 → 下一段文字（同图内）或翻到下一张图
- 点击屏幕左侧 / 左滑 → 上一段文字（同图内）或翻回上一张图
- 文字段切换时，当前段高亮，已读段灰化，未读段默认态

### 5.3 文字版阅读

文字版更简单，无图片，纯文字流：

```
故事列表 → 故事文字（连续滚动或翻页）→ 家长照念
```

文字版可复用绘本版的数据结构和阅读器组件，区别仅在于不渲染图片、文字段以连续文章形式展示。

---

## 6. 自动更新系统

### 6.1 整体流程

```
开发者推送代码 → GitLab CI 触发构建 → Flutter build APK/IPA
                                             │
                                             ▼
                                     上传产物到 Cloudflare R2
                                             │
                                             ▼
                                     更新版本清单 manifest.json
                                             │
                                             ▼
  App 启动时请求 manifest.json → 比对本地版本号 → 有新版？
                                             │
                                    ┌────────┴────────┐
                                    ▼ Yes             ▼ No
                           下载 APK/IPA        正常启动
                           → 提示安装更新
```

### 6.2 版本清单（CDN 侧）

在 Cloudflare R2（或 CDN 静态目录）上维护一个固定 URL 的版本清单文件：

```json
// https://<your-cdn-domain>/picture_book_reader/manifest.json
{
  "latestVersion": "0.1.0",
  "latestBuild": 3,
  "platforms": {
    "android": {
      "url": "https://<your-cdn-domain>/picture_book_reader/android/app-release-0.1.0-build3.apk",
      "sha256": "a1b2c3d4...",
      "sizeBytes": 8388608
    },
    "ios": {
      "url": "https://<your-cdn-domain>/picture_book_reader/ios/app-release-0.1.0-build3.ipa",
      "sha256": "e5f6g7h8...",
      "sizeBytes": 9437184
    }
  },
  "releaseNotes": "首次 MVP 版本",
  "minRequiredVersion": "0.0.1"
}
```

- `latestVersion` + `latestBuild`：语义化版本 + 构建号，App 用此判断是否需要更新
- `sha256`：下载后校验文件完整性
- `minRequiredVersion`：强制更新门槛——低于此版本的 App 必须更新才能使用

### 6.3 GitLab CI 流程

`.gitlab-ci.yml` 配置：

```yaml
stages:
  - build
  - publish

variables:
  FLUTTER_VERSION: "3.24.0"

build_android:
  stage: build
  image: ghcr.io/cirruslabs/flutter:$FLUTTER_VERSION
  script:
    - flutter pub get
    - flutter build apk --release --split-per-abi
    # 读取 pubspec.yaml 中的 version + build number
    - export APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
    - export BUILD_NUMBER=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 2)
    - mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk app-release-${APP_VERSION}-build${BUILD_NUMBER}.apk
  artifacts:
    paths:
      - app-release-*.apk
  only:
    - main
    - tags

publish_to_cdn:
  stage: publish
  image: amazon/aws-cli:latest
  script:
    - export APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
    - export BUILD_NUMBER=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 2)
    # 上传 APK 到 Cloudflare R2
    - aws s3 cp app-release-${APP_VERSION}-build${BUILD_NUMBER}.apk \
        s3://picture-book-reader/android/ \
        --endpoint-url $CLOUDFLARE_R2_ENDPOINT \
        --checksum-algorithm SHA256
    # 生成并上传 manifest.json
    - ./scripts/generate_manifest.sh $APP_VERSION $BUILD_NUMBER
    - aws s3 cp manifest.json \
        s3://picture-book-reader/manifest.json \
        --endpoint-url $CLOUDFLARE_R2_ENDPOINT
  only:
    - main
    - tags
```

### 6.4 客户端更新逻辑

```dart
/// 版本检查服务
class UpdateService {
  static const String _manifestUrl =
      'https://<your-cdn-domain>/picture_book_reader/manifest.json';

  /// 启动时检查更新
  Future<UpdateInfo?> checkForUpdate() async {
    final response = await http.get(Uri.parse(_manifestUrl));
    final manifest = jsonDecode(response.body);

    final currentVersion = await _getLocalVersion();
    final currentBuild = await _getLocalBuildNumber();

    final remoteVersion = manifest['latestVersion'] as String;
    final remoteBuild = manifest['latestBuild'] as int;

    // 版本号或构建号有更新
    if (_compareVersion(remoteVersion, currentVersion) > 0 ||
        (remoteVersion == currentVersion && remoteBuild > currentBuild)) {
      return UpdateInfo.fromManifest(manifest);
    }
    return null;
  }

  /// 下载并安装（Android）
  Future<void> downloadAndInstall(UpdateInfo info) async {
    // 1. 下载 APK 到临时目录
    final apkPath = await _downloadFile(info.androidUrl);

    // 2. SHA256 校验
    final hash = await _calculateSha256(apkPath);
    if (hash != info.androidSha256) {
      throw UpdateException('文件校验失败');
    }

    // 3. 调用系统安装器
    await _installApk(apkPath);
  }
}
```

**Android 安装**：下载 APK 后通过 `Intent` 调用系统包安装器，需在 `AndroidManifest.xml` 中配置 `REQUEST_INSTALL_PACKAGES` 权限和 `FileProvider`。

**iOS 更新（已排除）**：iOS 不在 MVP 范围。后续如需支持 iOS 更新，可参考以下方案：
- 方案 A：通过 TestFlight 分发（需要 Apple Developer 账号）
- 方案 B：企业证书 + OTA 分发（需企业账号）
- 方案 C：iOS 走 App Store / TestFlight，自动更新通道不实现

### 6.5 版本号规则

`pubspec.yaml` 中的版本号格式：

```yaml
version: 0.1.0+3
#         ^     ^
#         |     └─ build number（每次 CI 构建递增）
#         └─ semantic version（手动维护）
```

CI 打包时读取此字段，写入 `manifest.json`。App 端比对 `version` 和 `build number` 判断是否需要更新。

---

## 7. 项目目录结构

```
picture_book_reader/
├── lib/
│   ├── main.dart                      # 入口
│   ├── app.dart                       # MaterialApp 配置、路由
│   │
│   ├── core/
│   │   ├── constants.dart             # 常量（CDN URL、版本号等）
│   │   ├── theme.dart                 # 主题配置
│   │   └── router.dart                # 路由定义
│   │
│   ├── models/
│   │   ├── book.dart                  # Book 模型
│   │   ├── page.dart                  # Page 模型
│   │   ├── text_segment.dart          # TextSegment 模型
│   │   └── update_info.dart           # 更新信息模型
│   │
│   ├── services/
│   │   ├── book_service.dart          # 内置绘本加载、索引读取
│   │   └── update_service.dart        # 自动更新检测、下载、安装
│   │
│   ├── pages/
│   │   ├── mode_select_page.dart      # 模式选择页
│   │   ├── bookshelf_page.dart        # 书架列表页
│   │   ├── text_reader_page.dart      # 文字版阅读页
│   │   └── picture_reader_page.dart   # 绘本版阅读页
│   │
│   └── widgets/
│       ├── book_card.dart             # 书籍卡片
│       ├── text_segment_view.dart     # 文字段渲染组件
│       └── update_dialog.dart         # 更新提示弹窗
│
├── assets/
│   ├── books/
│   │   ├── index.json                 # 书架索引
│   │   └── book_001/                  # 示例绘本
│   │       ├── meta.json
│   │       ├── cover.png
│   │       └── page_01.png
│   └── icons/
│
├── scripts/
│   └── generate_manifest.sh           # CI 用：生成版本清单脚本
│
├── .gitlab-ci.yml                     # GitLab CI 配置
├── pubspec.yaml
└── README.md
```

---

## 8. 依赖清单（极简原则）

仅保留 MVP 必需依赖，能不引入就不引入：

| 依赖 | 用途 | 是否必须 |
|------|------|---------|
| `cupertino_icons` | iOS 风格图标 | 是（Flutter 默认） |
| `http` | 请求 CDN 版本清单 | 是 |
| `path_provider` | 获取临时下载目录 | 是 |
| `crypto` | SHA256 校验下载文件 | 是 |
| `provider` 或 `riverpod` | 状态管理（阅读器索引状态） | 待定，MVP 可先用 setState |

不引入路由框架（用 Flutter 内置 `Navigator`）、不引入网络框架（用 `http`）、不引入序列化代码生成（手写 `fromJson`）。包体优先控制在 10MB 以内。

---

## 9. 关键设计决策

**为什么选 Flutter 而不是 Cocos Creator**

绘本阅读 App 的核心是"图文展示 + 翻页交互"，不是游戏级动画。Flutter 的 `PageView` + `Stack` 组合天然适合一图多文的交互模型，且系统 UI 集成、上架流程、包体大小都优于 Cocos。自动更新方面，Flutter 产出的标准 APK 可直接下载安装，Cocos 打包的 App 在原生权限处理上更复杂。

**为什么自动更新优先于 MVP 功能**

后续每个功能迭代都需要在真机上验证。自动更新通道在框架阶段建好，意味着从第一个功能开始就能走"提交代码 → CI 打包 → CDN 分发 → 设备更新"的完整闭环，无需每次手动连接数据线安装。

**为什么 MVP 不做后端**

内置内容足以验证核心阅读体验。后端涉及账号、服务器、运维成本，在产品形态未定型前过早引入会分散精力。数据结构设计已预留在线扩展空间（`Book` 模型可从本地 JSON 扩展为远程 API 返回）。
