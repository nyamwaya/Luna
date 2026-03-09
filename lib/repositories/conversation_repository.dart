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
  static const int _defaultRecentMessageLimit = 30;
  static const Duration _sessionOpenerRefreshWindow = Duration(hours: 4);
  String? _lastSubscriptionFingerprint;

  Future<List<ConversationMessage>> loadRecentMessages({
    int limit = _defaultRecentMessageLimit,
  }) async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    await _ensureLocalUser(context.identity);
    final List<ConversationMessage> messages = await _loadMessages(context.conversationKey);
    if (messages.length <= limit) {
      return messages;
    }

    return messages.sublist(messages.length - limit);
  }

  Future<void> initializeSession() async {
    await _ensureConvexInitialized();
    final _ConversationContext context = await _loadConversationContext();
    await _ensureLocalUser(context.identity);
    final List<ConversationMessage> existingMessages = await _loadMessages(context.conversationKey);

    final Map<String, dynamic>? snapshot = await _loadColdStartSnapshot(context);
    if (snapshot == null) {
      return;
    }

    if (!_needsSessionOpener(existingMessages)) {
      return;
    }

    final String initPrompt = _buildInitPrompt(snapshot);
    await sendUserMessageAndGenerateReply(
      text: initPrompt,
      isHidden: true,
      metadata: const <String, dynamic>{
        'isSystemMessage': true,
      },
      assistantMetadata: <String, dynamic>{
        'isSessionOpener': true,
        'sessionOpenerDate': _sessionDayKey(DateTime.now()),
      },
    );
  }

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
        final List<ConversationMessage> messages = _deserializeMessages(value);
        final String fingerprint = _subscriptionFingerprint(messages);
        final bool isEmptyState = messages.isEmpty;
        if (_lastSubscriptionFingerprint != fingerprint) {
          _lastSubscriptionFingerprint = fingerprint;
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
        } else if (!isEmptyState) {
          AppLogger.info(
            'Subscription update received',
            data: <String, Object?>{
              'conversationKey': context.conversationKey,
              'userId': context.identity.userId,
              'messageCount': messages.length,
            },
          );
        }
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
    bool isHidden = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    Map<String, dynamic> assistantMetadata = const <String, dynamic>{},
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
          'isHidden': isHidden,
          'userId': context.identity.userId,
          ...metadata,
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
        'assistantMetadata': assistantMetadata,
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

  Future<Map<String, dynamic>?> _loadColdStartSnapshot(_ConversationContext context) async {
    final dynamic payload = await ConvexClient.instance.query(
      'appData:getColdStartSnapshot',
      <String, dynamic>{
        'userId': context.identity.userId,
        'userContext': context.identity.toContextJson(),
      },
    );
    if (payload is! Map || payload['snapshot'] is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(payload['snapshot'] as Map);
  }

  Future<List<ConversationMessage>> _loadMessages(String conversationKey) async {
    final dynamic latestMessagesPayload = await ConvexClient.instance.query(
      'messages:listByConversation',
      <String, dynamic>{
        'conversationKey': conversationKey,
      },
    );
    return _deserializeMessages(latestMessagesPayload);
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

  String _subscriptionFingerprint(List<ConversationMessage> messages) {
    if (messages.isEmpty) {
      return 'empty';
    }

    final ConversationMessage latestMessage = messages.last;
    return [
      messages.length,
      latestMessage.id,
      latestMessage.author.value,
      latestMessage.createdAt.millisecondsSinceEpoch,
    ].join(':');
  }

  String _buildInitPrompt(Map<String, dynamic> snapshot) {
    final Map<String, dynamic> user = _mapValue(snapshot['user']);
    final List<Map<String, dynamic>> circles = _mapList(snapshot['circles']);
    final List<Map<String, dynamic>> upcomingDinners = _mapList(snapshot['upcomingDinners']);
    final List<Map<String, dynamic>> pendingInvites = _mapList(snapshot['pendingInvites']);
    final List<Map<String, dynamic>> openDinnersNearby = _mapList(snapshot['openDinnersNearby']);
    final bool hasCircles = circles.isNotEmpty;
    final bool hasDinners = upcomingDinners.isNotEmpty;
    final bool hasInvites = pendingInvites.isNotEmpty;
    final bool hasOpenNearby = openDinnersNearby.isNotEmpty;
    final bool isNewUser = user['hasJoinedCircle'] != true;
    final String firstName = (user['firstName'] as String? ?? 'Friend').trim().isEmpty
        ? 'Friend'
        : user['firstName'] as String;

    final StringBuffer buffer = StringBuffer()
      ..writeln('[COLD START — generate session opener for $firstName]')
      ..writeln('Do not say "welcome back" or "hello". Lead with what matters.')
      ..writeln('Maximum 2 sentences before any widget.')
      ..writeln()
      ..writeln('Current user state:')
      ..writeln('- Circles: ${circles.length}')
      ..writeln('- Upcoming confirmed dinners: ${upcomingDinners.length}')
      ..writeln('- Pending invites not yet accepted: ${pendingInvites.length}')
      ..writeln('- Open dinners nearby with seats: ${openDinnersNearby.length}')
      ..writeln('- Account age: ${user['daysSinceCreated'] ?? 0} days')
      ..writeln();

    if (isNewUser && !hasCircles) {
      buffer.writeln('SCENARIO: Brand new user, no circles, no dinners.');
      buffer.writeln('INSTRUCTION: In one sentence explain what circles are — private groups where the same people rotate dinner partners so everyone gets to know each other. Then give them two clear paths: create a circle for a group they already have, or browse dinners near them to meet new people.');
      buffer.writeln('Show SuggestionChips using data.options with messages: Create a circle => "Create a circle", Find dinners near me => "Show me open dinners nearby."');
      buffer.writeln('Keep it under 3 sentences. Make it feel like an exciting beginning.');
    } else if (!hasCircles) {
      buffer.writeln('SCENARIO: Returning user but not in any circles.');
      buffer.writeln('INSTRUCTION: Note they are not in any circles yet. Nudge them toward joining or creating one — remind them that circles are how they get paired for dinners automatically.');
      buffer.writeln('Show SuggestionChips using data.options with messages: Create a circle => "Create a circle", Browse dinners near me => "Show me open dinners nearby."');
    } else if (hasInvites) {
      buffer.writeln('SCENARIO: User has pending dinner invites they have not accepted.');
      buffer.writeln('INSTRUCTION: Lead with the invite. This is the most urgent thing. Tell them they have a dinner invite waiting and surface it immediately.');
      buffer.writeln('Use widget type DinnerCard with the first invite mapped into data.');
      buffer.writeln('Data: ${jsonEncode(pendingInvites.first)}');
    } else if (hasDinners && hasCircles) {
      buffer.writeln('SCENARIO: User has circles and upcoming confirmed dinners. Healthy state.');
      buffer.writeln('INSTRUCTION: Greet them and surface their next confirmed dinner immediately. One sentence, warm, make the dinner feel close and real.');
      if (hasOpenNearby) {
        buffer.writeln('After that, add SuggestionChips with follow-up actions for nearby dinners and circles.');
      }
      buffer.writeln('Use widget type DinnerCard with this data: ${jsonEncode(upcomingDinners.first)}');
    } else if (hasCircles && !hasDinners) {
      buffer.writeln('SCENARIO: User is in circles but has no upcoming dinners. Needs activation.');
      buffer.writeln('INSTRUCTION: Greet them. Note that nothing is locked in yet.');
      if (hasOpenNearby) {
        buffer.writeln('Surface open dinners nearby as the clearest next step. Use DinnersList with the nearby dinners data.');
        buffer.writeln('Data: ${jsonEncode(openDinnersNearby.take(3).toList(growable: false))}');
      } else {
        buffer.writeln('Prompt them to create a circle or check their circles. End with SuggestionChips.');
      }
    }

    buffer.writeln();
    buffer.writeln('FORMAT RULES FOR THIS GREETING:');
    buffer.writeln('- Maximum 2 sentences of text before any widget');
    buffer.writeln('- Always end with a supported widget: SuggestionChips, DinnersList, CirclesList, CircleDetail, or DinnerCard');
    buffer.writeln('- SuggestionChips must use data.title, data.prompt, and data.options with {label, message} items');
    buffer.writeln('- DinnerCard data should match a single dinner summary shape with title, venue, city, dateLabel, and timeLabel');
    buffer.writeln('- Do not explain what you are unless it is the new user scenario');

    return buffer.toString();
  }

  bool _needsSessionOpener(List<ConversationMessage> messages) {
    if (messages.isEmpty) {
      return true;
    }

    final DateTime now = DateTime.now();
    final ConversationMessage? lastLumaMessage = _lastPersistentLumaMessage(messages);
    if (lastLumaMessage == null) {
      return true;
    }

    final bool isSessionOpener = lastLumaMessage.metadata['isSessionOpener'] == true;
    final bool isToday = _isSameDay(lastLumaMessage.createdAt, now);
    final int hoursSinceLastMessage = now.difference(messages.last.createdAt).inHours;
    if (isSessionOpener && isToday && hoursSinceLastMessage < _sessionOpenerRefreshWindow.inHours) {
      return false;
    }

    if (hoursSinceLastMessage >= _sessionOpenerRefreshWindow.inHours) {
      return true;
    }

    return false;
  }

  ConversationMessage? _lastPersistentLumaMessage(List<ConversationMessage> messages) {
    for (final ConversationMessage message in messages.reversed) {
      if (message.author != ConversationAuthor.luma) {
        continue;
      }

      if (message.metadata['activity'] == true) {
        continue;
      }

      return message;
    }

    return null;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  String _sessionDayKey(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }

  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value.whereType<Map>().map((Map item) => Map<String, dynamic>.from(item)).toList(growable: false);
}

class _ConversationContext {
  const _ConversationContext({
    required this.identity,
    required this.conversationKey,
  });

  final AppIdentity identity;
  final String conversationKey;
}
