import 'package:flutter/material.dart';

/// 书籍卡片
class BookCard extends StatelessWidget {
  final String title;
  final String? coverPath; // assets 内相对路径，null 显示占位
  final int? estimatedMinutes; // 预计阅读时长（分钟），非空时在标题下方显示
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.title,
    this.coverPath,
    this.estimatedMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildCover(),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (estimatedMinutes != null) ...[
                    const SizedBox(height: 4),
                    _DurationBadge(minutes: estimatedMinutes!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DurationBadge({required int minutes}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.brown.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12, color: Colors.brown.shade600),
            const SizedBox(width: 2),
            Text(
              '$minutes 分钟',
              style: TextStyle(
                fontSize: 11,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
      );

  Widget _buildCover() {
    if (coverPath == null || coverPath!.isEmpty) {
      return _placeholder();
    }
    if (coverPath!.startsWith('http://') || coverPath!.startsWith('https://')) {
      return Image.network(
        coverPath!,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _placeholder();
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.asset(
      'assets/$coverPath',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.brown.shade200, Colors.brown.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.auto_stories, size: 48, color: Colors.white70),
      );
}
