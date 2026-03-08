import 'package:convex_flutter/convex_flutter.dart';

import '../core/app_logger.dart';
import '../models/conversation_message.dart';
import '../services/convex_service.dart';

/// Repository responsible for Convex-backed conversation data access.
class ConversationRepository {
  static const String _defaultConversationKey = 'mobile-default';

  /// Ensures a default conversation exists for the current app session.
  Future<void> ensureDefaultConversation() async {
    await _ensureConvexInitialized();
    AppLogger.info(
      'Ensuring default conversation',
      data: <String, Object?>{'conversationKey': _defaultConversationKey},
    );

    await ConvexClient.instance.mutation(
      name: 'messages:ensureDefaultConversation',
      args: <String, dynamic>{
        'conversationKey': _defaultConversationKey,
      },
    );

    AppLogger.info(
      'Default conversation ensured',
      data: <String, Object?>{'conversationKey': _defaultConversationKey},
    );
  }

  /// Subscribes to live conversation messages.
  Future<dynamic> subscribeToMessages({
    required void Function(List<ConversationMessage> messages) onMessages,
    required void Function(String errorMessage) onError,
  }) async {
    await _ensureConvexInitialized();
    AppLogger.info(
      'Starting conversation subscription',
      data: <String, Object?>{'conversationKey': _defaultConversationKey},
    );

    return ConvexClient.instance.subscribe(
      name: 'messages:listByConversation',
      args: <String, dynamic>{
        'conversationKey': _defaultConversationKey,
      },
      onUpdate: (dynamic value) {
        final List<ConversationMessage> messages = _deserializeMessages(value);
        AppLogger.info(
          'Subscription update received',
          data: <String, Object?>{
            'conversationKey': _defaultConversationKey,
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

  /// Sends a user message and requests an assistant response via LLM action.
  Future<void> sendUserMessageAndGenerateReply({required String text}) async {
    await _ensureConvexInitialized();
    AppLogger.info(
      'Sending user message',
      data: <String, Object?>{'conversationKey': _defaultConversationKey, 'text': text},
    );

    await ConvexClient.instance.mutation(
      name: 'messages:sendUserMessage',
      args: <String, dynamic>{
        'conversationKey': _defaultConversationKey,
        'text': text,
      },
    );

    AppLogger.info(
      'User message persisted',
      data: <String, Object?>{'conversationKey': _defaultConversationKey},
    );

    final dynamic actionResponse = await ConvexClient.instance.action(
      name: 'llm:generateAssistantReply',
      args: <String, dynamic>{
        'conversationKey': _defaultConversationKey,
        'userText': text,
      },
    );

    AppLogger.info(
      'Assistant action completed',
      data: <String, Object?>{
        'conversationKey': _defaultConversationKey,
        'actionResponse': actionResponse?.toString(),
      },
    );
  }

  List<ConversationMessage> _deserializeMessages(dynamic value) {
    if (value is! List) {
      return const <ConversationMessage>[];
    }

    final List<ConversationMessage> messages = value
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
      return;
    }

    await ConvexService.initializeFromEnv();
  }
}
