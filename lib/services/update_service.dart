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
  int _localBuild = 0;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final info = await PackageInfo.fromPlatform();
    _localVersion = info.version;
    _localBuild = int.tryParse(info.buildNumber) ?? 0;
    _initialized = true;
  }

  Future<String> getLocalVersion() async {
    await _ensureInit();
    return _localVersion;
  }

  Future<int> getLocalBuild() async {
    await _ensureInit();
    return _localBuild;
  }

  Future<UpdateInfo?> checkForUpdate() async {
    await _ensureInit();
    debugPrint('[Update] local: version=$_localVersion build=$_localBuild');
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

    final remoteVersion = manifest['latestVersion'] as String;
    final remoteBuild = manifest['latestBuild'] as int;
    debugPrint('[Update] remote: version=$remoteVersion build=$remoteBuild');

    final hasNewVersion = _compareVersion(remoteVersion, _localVersion) > 0 ||
        (remoteVersion == _localVersion && remoteBuild > _localBuild);
    debugPrint('[Update] hasNewVersion=$hasNewVersion');
    if (hasNewVersion) {
      return UpdateInfo.fromManifest(manifest);
    }
    return null;
  }

  Future<bool> isForceUpdateRequired(UpdateInfo info) async {
    await _ensureInit();
    return _compareVersion(info.minRequiredVersion, _localVersion) > 0;
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
        '${dir.path}/app-release-${info.latestVersion}-build${info.latestBuild}.apk';

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

  int _compareVersion(String a, String b) {
    final pa = a.split('.').map(int.tryParse).whereType<int>().toList();
    final pb = b.split('.').map(int.tryParse).whereType<int>().toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
