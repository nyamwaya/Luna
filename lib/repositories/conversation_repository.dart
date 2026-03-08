import 'package:convex_flutter/convex_flutter.dart';
import 'dart:convert';

import '../core/app_logger.dart';
import '../models/conversation_message.dart';
import '../models/home/home_dashboard_view.dart';
import '../services/app_identity_service.dart';
import '../services/convex_service.dart';

/// Repository responsible for Convex-backed conversation data access.
class ConversationRepository {
  static const String _conversationNamespace = 'mobile';
  static const String _conversationVersion = 'tooling-v2';

  /// Ensures a default conversation exists for the current app session.
  Future<void> ensureDefaultConversation() async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    await _ensureLocalUser(context.identity);
    AppLogger.info(
      'Ensuring default conversation',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
      },
    );

    await ConvexClient.instance.mutation(
      name: 'messages:ensureDefaultConversation',
      args: <String, dynamic>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
      },
    );

    AppLogger.info(
      'Default conversation ensured',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
      },
    );
  }

  /// Subscribes to live conversation messages.
  Future<dynamic> subscribeToMessages({
    required void Function(List<ConversationMessage> messages) onMessages,
    required void Function(String errorMessage) onError,
  }) async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    AppLogger.info(
      'Starting conversation subscription',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
      },
    );

    return ConvexClient.instance.subscribe(
      name: 'messages:listByConversation',
      args: <String, dynamic>{
        'conversationKey': context.conversationKey,
      },
      onUpdate: (dynamic value) {
        AppLogger.info(
          'Subscription payload received',
          data: <String, Object?>{
            'runtimeType': value.runtimeType.toString(),
            'payloadPreview': value?.toString(),
          },
        );

        final List<ConversationMessage> messages = _deserializeMessages(value);
        AppLogger.info(
          'Subscription update received',
          data: <String, Object?>{
            'conversationKey': context.conversationKey,
            'userId': context.identity.userId,
            'messageCount': messages.length,
            'latestMessage': messages.isEmpty ? null : messages.last.text,
            'latestAuthor': messages.isEmpty ? null : messages.last.author.value,
          },
        );
        onMessages(messages);
      },
      onError: (String message, dynamic value) {
        AppLogger.error(
          'Conversation subscription failed',
          data: <String, Object?>{'message': message, 'value': value?.toString()},
        );
        onError(message);
      },
    );
  }

  /// Sends a user message, requests an assistant response, and returns
  /// the latest conversation snapshot.
  Future<List<ConversationMessage>> sendUserMessageAndGenerateReply({
    required String text,
  }) async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    await _ensureLocalUser(context.identity);
    AppLogger.info(
      'Sending user message',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
        'text': text,
      },
    );

    await ConvexClient.instance.mutation(
      name: 'messages:sendUserMessage',
      args: <String, dynamic>{
        'conversationKey': context.conversationKey,
        'text': text,
        'metadata': <String, dynamic>{
          'userId': context.identity.userId,
        },
      },
    );

    AppLogger.info(
      'User message persisted',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
      },
    );

    final dynamic actionResponse = await ConvexClient.instance.action(
      name: 'llm:generateAssistantReply',
      args: <String, dynamic>{
        'conversationKey': context.conversationKey,
        'userText': text,
        'userId': context.identity.userId,
        'userContext': context.identity.toContextJson(),
      },
    );

    AppLogger.info(
      'Assistant action completed',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
        'actionResponse': actionResponse?.toString(),
      },
    );

    final dynamic latestMessagesPayload = await ConvexClient.instance.query(
      'messages:listByConversation',
      <String, dynamic>{
        'conversationKey': context.conversationKey,
      },
    );

    AppLogger.info(
      'Latest message payload received',
      data: <String, Object?>{
        'runtimeType': latestMessagesPayload.runtimeType.toString(),
        'payloadPreview': latestMessagesPayload?.toString(),
      },
    );

    final List<ConversationMessage> latestMessages = _deserializeMessages(
      latestMessagesPayload,
    );
    AppLogger.info(
      'Latest message snapshot fetched',
      data: <String, Object?>{
        'conversationKey': context.conversationKey,
        'userId': context.identity.userId,
        'messageCount': latestMessages.length,
      },
    );

    return latestMessages;
  }

  Future<HomeDashboardView?> loadHomeDashboard() async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    await _ensureLocalUser(context.identity);
    final dynamic payload = await ConvexClient.instance.query(
      'appData:getHomeDashboard',
      <String, dynamic>{
        'userId': context.identity.userId,
        'userContext': context.identity.toContextJson(),
      },
    );

    if (payload is! Map || payload['view'] is! Map) {
      return null;
    }

    return HomeDashboardView.fromJson(
      Map<String, dynamic>.from(payload['view'] as Map),
    );
  }

  Future<String> resetConversation() async {
    await _ensureConvexInitialized();
    final _ConversationContext previousContext = await _loadConversationContext();
    await AppIdentityService.rotateConversationSession();
    final _ConversationContext nextContext = await _loadConversationContext();
    await _ensureLocalUser(nextContext.identity);

    AppLogger.info(
      'Conversation reset requested',
      data: <String, Object?>{
        'previousConversationKey': previousContext.conversationKey,
        'conversationKey': nextContext.conversationKey,
        'userId': nextContext.identity.userId,
      },
    );

    await ConvexClient.instance.mutation(
      name: 'messages:ensureDefaultConversation',
      args: <String, dynamic>{
        'conversationKey': nextContext.conversationKey,
        'userId': nextContext.identity.userId,
      },
    );

    return nextContext.conversationKey;
  }

  List<ConversationMessage> _deserializeMessages(dynamic value) {
    dynamic normalizedValue = value;

    if (normalizedValue is String && normalizedValue.isNotEmpty) {
      try {
        normalizedValue = jsonDecode(normalizedValue);
      } catch (_) {
        return const <ConversationMessage>[];
      }
    }

    if (normalizedValue is Map) {
      if (normalizedValue['value'] is List) {
        normalizedValue = normalizedValue['value'];
      } else if (normalizedValue['items'] is List) {
        normalizedValue = normalizedValue['items'];
      }
    }

    if (normalizedValue is! List) {
      return const <ConversationMessage>[];
    }

    final List<ConversationMessage> messages = normalizedValue
        .whereType<Map>()
        .map(
          (Map dynamicMap) => ConversationMessage.fromJson(
            Map<String, dynamic>.from(dynamicMap),
          ),
        )
        .toList(growable: false)
      ..sort(
        (ConversationMessage a, ConversationMessage b) =>
            a.createdAt.compareTo(b.createdAt),
      );

    return messages;
  }

  Future<void> _ensureConvexInitialized() async {
    if (ConvexService.isInitialized) {
      await AppIdentityService.initialize();
      return;
    }

    await ConvexService.initializeFromEnv();
    await AppIdentityService.initialize();
  }

  Future<_ConversationContext> _loadConversationContext() async {
    final AppIdentity identity = await AppIdentityService.currentIdentity();
    final String sessionId = await AppIdentityService.currentConversationSessionId();
    return _ConversationContext(
      identity: identity,
      conversationKey:
          '$_conversationNamespace-$_conversationVersion-${identity.userId}-$sessionId',
    );
  }

  Future<void> _ensureLocalUser(AppIdentity identity) async {
    await ConvexClient.instance.mutation(
      name: 'appData:ensureLocalUser',
      args: <String, dynamic>{
        'userId': identity.userId,
        'userContext': identity.toContextJson(),
      },
    );
  }
}

class _ConversationContext {
  const _ConversationContext({
    required this.identity,
    required this.conversationKey,
  });

  final AppIdentity identity;
  final String conversationKey;
}
