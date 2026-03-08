import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/shell/conversation_shell.dart';

class AppRouter {
  static const String shell = '/';
  static const String circleDetail = '/circle';
  static const String circleDetailAdmin = '/circle/admin';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  static final router = GoRouter(
    initialLocation: shell,
    observers: <NavigatorObserver>[
      _FocusDismissNavigatorObserver(),
    ],
    routes: [
      GoRoute(
        path: shell,
        builder: (context, state) => const ConversationShell(),
      ),
      // Placeholder routes for screens
      GoRoute(
        path: profile,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Profile Screen'))),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Settings Screen'))),
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Notifications Screen'))),
      ),
    ],
  );
}

class _FocusDismissNavigatorObserver extends NavigatorObserver {
  void _dismissFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissFocus();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissFocus();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissFocus();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismissFocus();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
