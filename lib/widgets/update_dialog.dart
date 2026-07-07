import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final bool force;

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

  String? get _platformUrl =>
      Platform.isAndroid ? widget.info.android?.url : widget.info.ios?.url;

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
              '版本 ${widget.info.latestVersion} (${widget.info.latestVersionCode})',
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
          if (_platformUrl != null)
            TextButton(
              onPressed: _downloading ? null : _openInBrowser,
              child: const Text('浏览器下载'),
            ),
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
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e。可改用浏览器下载。')),
        );
      }
    }
  }

  Future<void> _openInBrowser() async {
    final url = _platformUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，请手动复制链接下载')),
        );
      }
    }
  }
}
