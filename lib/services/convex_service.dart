import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../core/app_logger.dart';

/// Initializes and provides access to the global Convex client instance.
abstract final class ConvexService {
  static const String _envKeyConvexDevUrl = 'CONVEX_DEV_URL';
  static const String _envKeyConvexDeploymentUrl = 'CONVEX_DEPLOYMENT_URL';
  static const String _envKeyConvexUrl = 'CONVEX_URL';

  static bool _isInitialized = false;

  /// Initializes Convex using deployment URL values from `.env`.
  ///
  /// Accepted environment keys (in priority order):
  /// - `CONVEX_DEV_URL`
  /// - `CONVEX_DEPLOYMENT_URL`
  /// - `CONVEX_URL`
  static Future<void> initializeFromEnv() async {
    if (_isInitialized) {
      return;
    }

    final String? deploymentUrl = _readDeploymentUrl();
    if (deploymentUrl == null || deploymentUrl.trim().isEmpty) {
      AppLogger.warning(
        'Convex initialization skipped: deployment URL missing in environment',
        data: <String, Object?>{
          'acceptedKeys': <String>[
            _envKeyConvexDevUrl,
            _envKeyConvexDeploymentUrl,
            _envKeyConvexUrl,
          ],
        },
      );
      return;
    }

    await ConvexClient.initialize(
      ConvexConfig(
        deploymentUrl: deploymentUrl,
        clientId: 'luma-flutter',
        operationTimeout: const Duration(seconds: 30),
        healthCheckQuery: 'health:ping',
      ),
    );

    _isInitialized = true;
    AppLogger.info(
      'Convex initialized',
      data: <String, Object?>{'deploymentUrl': deploymentUrl},
    );
  }

  static String? _readDeploymentUrl() {
    final String devUrl = dotenv.env[_envKeyConvexDevUrl] ?? '';
    if (devUrl.trim().isNotEmpty) {
      return devUrl.trim();
    }

    final String deploymentUrl = dotenv.env[_envKeyConvexDeploymentUrl] ?? '';
    if (deploymentUrl.trim().isNotEmpty) {
      return deploymentUrl.trim();
    }

    final String convexUrl = dotenv.env[_envKeyConvexUrl] ?? '';
    if (convexUrl.trim().isNotEmpty) {
      return convexUrl.trim();
    }

    return null;
  }
}
