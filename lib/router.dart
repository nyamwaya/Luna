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
