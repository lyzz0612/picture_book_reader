import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';

class PictureBookApp extends StatelessWidget {
  const PictureBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '绘本阅读',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.modeSelect,
    );
  }
}
