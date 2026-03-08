import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_logger.dart';
import 'services/convex_service.dart';
import 'router.dart';
import 'styles/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Failed to load .env file',
      data: <String, Object?>{'error': error.toString(), 'stackTrace': stackTrace.toString()},
    );
  }

  try {
    await ConvexService.initializeFromEnv();
  } catch (error, stackTrace) {
    AppLogger.error(
      'Convex initialization failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

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
      builder: (BuildContext context, Widget? child) {
        return _AppFocusDismissScope(
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: AppRouter.router,
    );
  }
}

class _AppFocusDismissScope extends StatelessWidget {
  const _AppFocusDismissScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        final FocusNode? focus = FocusManager.instance.primaryFocus;
        if (focus == null) {
          return;
        }

        final BuildContext? focusContext = focus.context;
        final RenderObject? renderObject = focusContext?.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.attached) {
          focus.unfocus();
          return;
        }

        final Offset origin = renderObject.localToGlobal(Offset.zero);
        final Rect bounds = origin & renderObject.size;
        if (!bounds.contains(event.position)) {
          focus.unfocus();
        }
      },
      child: child,
    );
  }
}
