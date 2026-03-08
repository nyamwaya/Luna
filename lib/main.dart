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
