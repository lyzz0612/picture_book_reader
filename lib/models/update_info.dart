/// 单平台更新包信息
class PlatformUpdateInfo {
  final String url; // 下载地址
  final String sha256; // 文件校验值
  final int sizeBytes; // 文件大小（字节）

  const PlatformUpdateInfo({
    required this.url,
    required this.sha256,
    required this.sizeBytes,
  });

  factory PlatformUpdateInfo.fromJson(Map<String, dynamic> json) {
    return PlatformUpdateInfo(
      url: json['url'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: json['sizeBytes'] as int,
    );
  }
}

/// 远端版本清单解析结果
class UpdateInfo {
  final String latestVersion; // versionName，如 "0.1.16"
  final int latestVersionCode; // versionCode，整数，如 10016
  final PlatformUpdateInfo? android;
  final PlatformUpdateInfo? ios;
  final String releaseNotes; // 更新说明
  final String minRequiredVersion; // 低于此版本强制更新（versionName 格式）

  const UpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    this.android,
    this.ios,
    required this.releaseNotes,
    required this.minRequiredVersion,
  });

  factory UpdateInfo.fromManifest(Map<String, dynamic> manifest) {
    final platforms = (manifest['platforms'] as Map<String, dynamic>?) ?? {};
    return UpdateInfo(
      latestVersion: manifest['latestVersion'] as String,
      latestVersionCode: manifest['latestVersionCode'] as int,
      android: platforms['android'] != null
          ? PlatformUpdateInfo.fromJson(platforms['android'] as Map<String, dynamic>)
          : null,
      ios: platforms['ios'] != null
          ? PlatformUpdateInfo.fromJson(platforms['ios'] as Map<String, dynamic>)
          : null,
      releaseNotes: (manifest['releaseNotes'] as String?) ?? '',
      minRequiredVersion: (manifest['minRequiredVersion'] as String?) ?? '0.0.0',
    );
  }
}
