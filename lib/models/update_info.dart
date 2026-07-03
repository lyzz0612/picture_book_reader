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
  final String latestVersion; // 最新语义化版本
  final int latestBuild; // 最新构建号
  final PlatformUpdateInfo? android;
  final PlatformUpdateInfo? ios;
  final String releaseNotes; // 更新说明
  final String minRequiredVersion; // 低于此版本强制更新

  const UpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    this.android,
    this.ios,
    required this.releaseNotes,
    required this.minRequiredVersion,
  });

  factory UpdateInfo.fromManifest(Map<String, dynamic> manifest) {
    final platforms = (manifest['platforms'] as Map<String, dynamic>?) ?? {};
    return UpdateInfo(
      latestVersion: manifest['latestVersion'] as String,
      latestBuild: manifest['latestBuild'] as int,
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
