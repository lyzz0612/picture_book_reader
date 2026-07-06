/// 全局常量
class AppConstants {
  AppConstants._();

  /// CDN 版本清单 URL
  ///
  /// 配置优先级（从高到低）：
  /// 1. 运行时参数：`flutter run --dart-define=APP_MANIFEST_URL=https://xxx/manifest.json`
  /// 2. 环境变量：运行前设置 `export APP_MANIFEST_URL=https://xxx/manifest.json`
  /// 3. 默认值：下面的 defaultValue
  static const String manifestUrl = String.fromEnvironment(
    'APP_MANIFEST_URL',
    defaultValue: 'https://r2.skyup.top/picture-book/manifest.json',
  );

  /// 版本清单请求超时
  static const Duration manifestTimeout = Duration(seconds: 10);
}
