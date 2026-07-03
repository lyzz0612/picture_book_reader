import 'text_segment.dart';

/// 页面（绘本版：一张图 + 多段文字；文字版：纯多段文字）
class Page {
  final String id;
  final String? imagePath; // 图片路径（文字版为 null）
  final List<TextSegment> segments; // 文字段列表

  const Page({
    required this.id,
    this.imagePath,
    required this.segments,
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String?,
      segments: (json['segments'] as List)
          .map((e) => TextSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
