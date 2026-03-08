import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'styles/app_colors.dart';

void main() {
  runApp(
    const ProviderScope(
      child: LumaApp(),
    ),
  );
}

class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Luma',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          primary: AppColors.gold,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.white,
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
