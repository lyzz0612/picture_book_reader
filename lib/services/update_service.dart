import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/update_info.dart';

class UpdateException implements Exception {
  final String message;
  UpdateException(this.message);
  @override
  String toString() => 'UpdateException: $message';
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const MethodChannel _installerChannel = MethodChannel('app.installer');

  String _localVersion = '0.0.0';
  int _localVersionCode = 0;
  String _lastRemoteVersion = '';
  int _lastRemoteVersionCode = 0;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final info = await PackageInfo.fromPlatform();
    _localVersion = info.version;
    _localVersionCode = int.tryParse(info.buildNumber) ?? 0;
    _initialized = true;
  }

  Future<String> getLocalVersion() async {
    await _ensureInit();
    return _localVersion;
  }

  Future<int> getLocalVersionCode() async {
    await _ensureInit();
    return _localVersionCode;
  }

  String get lastRemoteVersion => _lastRemoteVersion;
  int get lastRemoteVersionCode => _lastRemoteVersionCode;

  Future<UpdateInfo?> checkForUpdate() async {
    await _ensureInit();
    debugPrint('[Update] local: version=$_localVersion code=$_localVersionCode');
    debugPrint('[Update] request: ${AppConstants.manifestUrl}');
    final response = await http
        .get(Uri.parse(AppConstants.manifestUrl))
        .timeout(AppConstants.manifestTimeout);
    debugPrint('[Update] response: status=${response.statusCode} '
        'len=${response.body.length}');
    if (response.statusCode != 200) {
      throw UpdateException('获取版本清单失败: HTTP ${response.statusCode}');
    }
    final manifest = jsonDecode(response.body) as Map<String, dynamic>;

    final info = UpdateInfo.fromManifest(manifest);
    _lastRemoteVersion = info.latestVersion;
    _lastRemoteVersionCode = info.latestVersionCode;
    debugPrint('[Update] remote: version=${info.latestVersion} '
        'code=${info.latestVersionCode}');

    // versionCode 是单调递增的整数，直接比较即可判断是否有新版本
    final hasNewVersion = info.latestVersionCode > _localVersionCode;
    debugPrint('[Update] hasNewVersion=$hasNewVersion');
    return hasNewVersion ? info : null;
  }

  Future<bool> isForceUpdateRequired(UpdateInfo info) async {
    await _ensureInit();
    final minRequiredCode = _computeVersionCode(info.minRequiredVersion);
    return minRequiredCode > _localVersionCode;
  }

  Future<void> downloadAndInstall(
    UpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    final platformInfo = info.android;
    if (platformInfo == null) {
      throw UpdateException('当前无 Android 更新包');
    }

    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/app-release-${info.latestVersion}-${info.latestVersionCode}.apk';

    await _downloadFile(platformInfo.url, filePath, onProgress: onProgress);

    final hash = await _calculateSha256(filePath);
    if (hash != platformInfo.sha256) {
      File(filePath).deleteSync();
      throw UpdateException('文件校验失败');
    }

    await _installApk(filePath);
  }

  Future<void> _downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw UpdateException('下载失败: ${response.statusCode}');
      }
      final total = response.contentLength ?? 0;
      final sink = File(savePath).openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<String> _calculateSha256(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<void> _installApk(String filePath) async {
    if (!Platform.isAndroid) {
      throw UpdateException('仅支持 Android 自动安装，iOS 请走 TestFlight');
    }
    try {
      await _installerChannel.invokeMethod('installApk', {'path': filePath});
    } on PlatformException catch (e) {
      throw UpdateException('安装失败: ${e.message ?? e.code}');
    }
  }

  /// versionCode 计算公式: patch + minor×10000 + major×1000000
  /// 例: "0.1.16" → 16 + 1×10000 + 0×1000000 = 10016
  int _computeVersionCode(String versionName) {
    final parts = versionName.split('.').map(int.tryParse).whereType<int>().toList();
    final major = parts.isNotEmpty ? parts[0] : 0;
    final minor = parts.length > 1 ? parts[1] : 0;
    final patch = parts.length > 2 ? parts[2] : 0;
    return patch + minor * 10000 + major * 1000000;
  }
}
