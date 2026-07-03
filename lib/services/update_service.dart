import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../models/update_info.dart';
import '../widgets/update_dialog.dart';

/// 更新异常
class UpdateException implements Exception {
  final String message;
  UpdateException(this.message);
  @override
  String toString() => 'UpdateException: $message';
}

/// 版本检查 + 下载 + 安装服务
///
/// 流程：启动请求 manifest.json → 比对本地版本号 → 有新版弹窗
/// → 用户确认 → 下载 APK → SHA256 校验 → 调用系统安装器
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Android 系统安装器通道（对应 MainActivity 中的 MethodChannel）
  static const MethodChannel _installerChannel = MethodChannel('app.installer');

  GlobalKey<NavigatorState>? _navigatorKey;
  String _localVersion = '0.0.0';
  int _localBuild = 0;
  bool _initialized = false;
  bool _checking = false;

  void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final info = await PackageInfo.fromPlatform();
    _localVersion = info.version;
    _localBuild = int.tryParse(info.buildNumber) ?? 0;
    _initialized = true;
  }

  /// 启动时静默检查更新，有新版本则弹窗
  Future<void> checkForUpdateOnLaunch() async {
    if (_checking) return;
    _checking = true;
    try {
      final info = await checkForUpdate();
      if (info != null) {
        final force =
            _compareVersion(info.minRequiredVersion, _localVersion) > 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(info, force: force);
        });
      }
    } catch (_) {
      // 静默失败，不打扰用户
    } finally {
      _checking = false;
    }
  }

  /// 主动检查更新，返回更新信息或 null
  Future<UpdateInfo?> checkForUpdate() async {
    await _ensureInit();
    final response = await http
        .get(Uri.parse(AppConstants.manifestUrl))
        .timeout(AppConstants.manifestTimeout);
    if (response.statusCode != 200) return null;
    final manifest = jsonDecode(response.body) as Map<String, dynamic>;

    final remoteVersion = manifest['latestVersion'] as String;
    final remoteBuild = manifest['latestBuild'] as int;

    // 版本号或构建号有更新
    if (_compareVersion(remoteVersion, _localVersion) > 0 ||
        (remoteVersion == _localVersion && remoteBuild > _localBuild)) {
      return UpdateInfo.fromManifest(manifest);
    }
    return null;
  }

  /// 下载并安装（Android）
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

    // 1. 下载到临时目录
    await _downloadFile(platformInfo.url, filePath, onProgress: onProgress);

    // 2. SHA256 校验
    final hash = await _calculateSha256(filePath);
    if (hash != platformInfo.sha256) {
      File(filePath).deleteSync();
      throw UpdateException('文件校验失败');
    }

    // 3. 调用系统安装器
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

  void _showUpdateDialog(UpdateInfo info, {required bool force}) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (_) => UpdateDialog(info: info, force: force),
    );
  }

  /// 语义化版本比较：>0 表示 a 更新，<0 表示 b 更新，0 表示相同
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
