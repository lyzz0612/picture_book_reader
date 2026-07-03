import 'package:flutter/material.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

/// 更新提示弹窗
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final bool force; // 强制更新（低于 minRequiredVersion）

  const UpdateDialog({
    super.key,
    required this.info,
    required this.force,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.force,
      child: AlertDialog(
        title: Text(widget.force ? '必须更新' : '发现新版本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本 ${widget.info.latestVersion} (build ${widget.info.latestBuild})',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(widget.info.releaseNotes.isEmpty
                ? '暂无更新说明'
                : widget.info.releaseNotes),
            const SizedBox(height: 12),
            if (_downloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],
          ],
        ),
        actions: [
          if (!widget.force)
            TextButton(
              onPressed: _downloading ? null : () => Navigator.pop(context),
              child: const Text('稍后再说'),
            ),
          ElevatedButton(
            onPressed: _downloading ? null : _startDownload,
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      await UpdateService.instance.downloadAndInstall(
        widget.info,
        onProgress: (r, t) {
          if (t > 0) setState(() => _progress = r / t);
        },
      );
      // 安装器拉起后，App 会被系统暂停，用户安装完重启即可
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }
}
