import 'package:flutter/material.dart';
import '../models/text_segment.dart';

/// 文字段渲染状态
enum SegmentState {
  unread, // 未读
  current, // 当前（高亮）
  read, // 已读（灰化）
}

/// 文字段渲染组件
class TextSegmentView extends StatelessWidget {
  final TextSegment segment;
  final SegmentState state;

  const TextSegmentView({
    super.key,
    required this.segment,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final (color, weight) = switch (state) {
      SegmentState.current => (Colors.white, FontWeight.w600),
      SegmentState.read => (Colors.white54, FontWeight.normal),
      SegmentState.unread => (Colors.white38, FontWeight.normal),
    };
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: 18,
        height: 1.6,
        color: color,
        fontWeight: weight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(segment.text),
      ),
    );
  }
}
