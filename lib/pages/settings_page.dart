import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '';
  int _build = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await UpdateService.instance.getLocalVersion();
    final b = await UpdateService.instance.getLocalBuild();
    if (!mounted) return;
    setState(() {
      _version = v;
      _build = b;
    });
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final info = await UpdateService.instance.checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        final rv = UpdateService.instance.lastRemoteVersion;
        final rb = UpdateService.instance.lastRemoteBuild;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rv.isEmpty
                ? '已是最新版本'
                : '已是最新版本（本地 build $_build / 远端 $rv build $rb）'),
          ),
        );
      } else {
        final force = await UpdateService.instance.isForceUpdateRequired(info);
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: !force,
          builder: (_) => UpdateDialog(info: info, force: force),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('检查更新失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('当前版本'),
            trailing: Text(
              _version.isEmpty ? '加载中…' : '$_version (build $_build)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('检查更新'),
            subtitle: const Text('手动检查是否有新版本，下载并安装'),
            trailing: _checking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _checking ? null : _checkUpdate,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('关于更新'),
            subtitle: const Text('应用内下载失败时，可在更新弹窗中改用浏览器下载'),
          ),
        ],
      ),
    );
  }
}
