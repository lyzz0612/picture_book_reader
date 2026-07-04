/// 全局常量
class AppConstants {
  AppConstants._();

  /// CDN 版本清单 URL（固定地址）
  ///
  /// 默认值为占位地址，需通过以下任一方式配置真实地址：
  /// 1. 修改此 defaultValue；
  /// 2. 运行时 --dart-define=APP_MANIFEST_URL=https://<your-cdn>/picture_book_reader/manifest.json
  static const String manifestUrl = String.fromEnvironment(
    'APP_MANIFEST_URL',
    defaultValue:
        'https://CHANGE_ME.cdn.example.com/picture_book_reader/manifest.json',
  );

  /// 版本清单请求超时
  static const Duration manifestTimeout = Duration(seconds: 10);
}
