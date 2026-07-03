/// 文字段
class TextSegment {
  final String id;
  final String text; // 文字内容
  final int? durationHint; // 预计朗读时长（秒），用于自动切换提示

  const TextSegment({
    required this.id,
    required this.text,
    this.durationHint,
  });

  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      id: json['id'] as String,
      text: json['text'] as String,
      durationHint: json['durationHint'] as int?,
    );
  }
}
