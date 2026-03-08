# architecture.md — Luma

---

## Overview

Luma is a Flutter app with a Supabase backend. The UI is driven by a single conversational shell — not a traditional screen-per-route model. Almost all user-facing interactions are widgets rendered inside that shell, triggered by agent responses and backend state changes.

Read this file before making any structural change or starting any new feature.

---

## Folder Structure

```
lib/
├── agent/
│   ├── tools/                  # One file per tool definition
│   │   ├── confirm_match_tool.dart
│   │   ├── decline_match_tool.dart
│   │   └── ...
│   ├── tool_registry.dart      # Registers all tools, maps name → handler
│   ├── agent_service.dart      # Sends messages to Claude, handles tool_use blocks
│   └── agent_state.dart        # Conversation history, pending tool calls
│
├── models/
│   ├── circle.dart
│   ├── dinner_event.dart
│   ├── dinner_match.dart
│   ├── dinner_invite.dart
│   ├── match_guest.dart
│   ├── notification.dart
│   └── user_profile.dart
│
├── repositories/
│   ├── circle_repository.dart
│   ├── dinner_repository.dart
│   ├── match_repository.dart
│   ├── notification_repository.dart
│   └── user_repository.dart
│
├── services/
│   ├── supabase_service.dart   # Supabase client singleton
│   ├── realtime_service.dart   # All Realtime subscriptions
│   ├── fcm_service.dart        # Firebase Cloud Messaging
│   ├── auth_service.dart       # Auth state, sign in, sign out
│   └── storage_service.dart    # Profile photo uploads
│
├── screens/
│   ├── shell/
│   │   ├── conversation_shell.dart        # Root shell screen
│   │   └── conversation_shell_state.dart  # Shell state management
│   ├── circle_detail/
│   │   ├── circle_detail_screen.dart
│   │   └── circle_detail_admin_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
├── widgets/
│   ├── conversation/           # Contextual widgets rendered in the shell feed
│   │   ├── dinner_invite_card.dart
│   │   ├── waiting_for_pairs_card.dart
│   │   ├── pair_reveal_card.dart
│   │   ├── waiting_for_partner_card.dart
│   │   ├── partner_declined_card.dart
│   │   ├── confirmed_dinner_card.dart
│   │   ├── check_in_widget.dart
│   │   ├── attendance_report_card.dart
│   │   ├── feedback_widget.dart
│   │   ├── circle_found_card.dart
│   │   └── circle_preview_card.dart
│   ├── luma_message.dart       # Agent text bubble
│   ├── user_bubble.dart        # User text bubble
│   ├── quick_reply_chips.dart
│   ├── context_strip.dart      # Breadcrumb bar beneath top bar
│   └── shared/                 # Buttons, inputs, avatars, tags, etc.
│
├── styles/
│   ├── app_colors.dart
│   ├── dimensions.dart
│   └── text_styles.dart
│
├── strings.dart                # All user-facing text
├── router.dart                 # Named routes for true screens only
└── main.dart
```

---

## Layered Architecture

Every feature follows the same four-layer pattern. Do not skip layers or call Supabase directly from a screen or widget.

```
Screen / Widget
      ↓
  Repository          ← data access, Supabase calls, RPC calls
      ↓
    Model             ← typed, null-safe data classes
      ↓
  Supabase / API
```

The `service` layer sits alongside repositories for cross-cutting concerns (auth, FCM, Realtime, storage). It does not hold business logic.

---

## Models

Every model is a plain Dart class with:
- Named, required constructor
- `fromJson(Map<String, dynamic> json)` factory
- `toJson()` method
- `copyWith()` method
- All fields explicitly typed and null-safe

### Example

```dart
// lib/models/dinner_match.dart

class DinnerMatch {
  final String id;
  final String dinnerEventId;
  final MatchStatus status;
  final DateTime? revealAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DinnerMatch({
    required this.id,
    required this.dinnerEventId,
    required this.status,
    this.revealAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DinnerMatch.fromJson(Map<String, dynamic> json) {
    return DinnerMatch(
      id: json['id'] as String,
      dinnerEventId: json['dinner_event_id'] as String,
      status: MatchStatus.fromString(json['status'] as String),
      revealAt: json['reveal_at'] != null
          ? DateTime.parse(json['reveal_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'dinner_event_id': dinnerEventId,
    'status': status.value,
    'reveal_at': revealAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  DinnerMatch copyWith({
    String? id,
    String? dinnerEventId,
    MatchStatus? status,
    DateTime? revealAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DinnerMatch(
      id: id ?? this.id,
      dinnerEventId: dinnerEventId ?? this.dinnerEventId,
      status: status ?? this.status,
      revealAt: revealAt ?? this.revealAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum MatchStatus {
  pending('pending'),
  revealed('revealed'),
  confirmed('confirmed'),
  completed('completed'),
  expired('expired'),
  cancelled('cancelled');

  final String value;
  const MatchStatus(this.value);

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => throw ArgumentError('Unknown MatchStatus: $value'),
    );
  }
}
```

---

## Repositories

Repositories own all data access. They call Supabase RPCs or table queries, parse the response into models, and return a typed `Result`.

### Result type

All repository methods return a `Result<T>` — never throw directly to the UI.

```dart
// lib/core/result.dart

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  const Failure(this.message, {this.error});
}
```

### Example repository

```dart
// lib/repositories/match_repository.dart

class MatchRepository {
  final SupabaseClient _client;

  MatchRepository(this._client);

  Future<Result<DinnerMatch>> confirmMatchGuest({
    required String matchId,
    required String userId,
  }) async {
    try {
      final response = await _client.rpc('confirm_match_guest', params: {
        'p_match_id': matchId,
        'p_user_id': userId,
      });

      if (response['error'] != null) {
        return Failure(response['error'] as String);
      }

      final match = await _getMatch(matchId);
      return Success(match);
    } catch (e) {
      AppLogger.error('confirmMatchGuest failed', error: e);
      return Failure('Failed to confirm match', error: e);
    }
  }

  Future<Result<MatchDetail>> getMatchDetail({
    required String matchId,
    required String viewerUserId,
  }) async {
    try {
      final response = await _client.rpc('get_match_detail', params: {
        'p_match_id': matchId,
        'p_viewer_user_id': viewerUserId,
      });

      return Success(MatchDetail.fromJson(response as Map<String, dynamic>));
    } catch (e) {
      AppLogger.error('getMatchDetail failed', error: e);
      return Failure('Failed to load match detail', error: e);
    }
  }
}
```

### Rules
- One repository per domain (circles, matches, dinners, users, notifications)
- Never call `_client` from a widget or screen directly
- Always log errors with `AppLogger` before returning `Failure`
- Never return null — use `Result<T>` or `Result<T?>` explicitly

---

## Conversation Shell

The shell is the root screen for all agent-driven flows. It owns the conversation feed and decides which contextual widget to render based on the current `ShellState`.

### Shell state

```dart
// lib/screens/shell/conversation_shell_state.dart

enum ShellWidget {
  none,
  dinnerInvite,
  waitingForPairs,
  pairReveal,
  waitingForPartner,
  partnerDeclined,
  confirmedDinner,
  checkIn,
  attendanceReport,
  feedback,
  circleFound,
  circlePreview,
}

class ShellState {
  final List<ConversationMessage> messages;
  final ShellWidget activeWidget;
  final Map<String, dynamic> widgetData;
  final bool isLoading;

  const ShellState({
    this.messages = const [],
    this.activeWidget = ShellWidget.none,
    this.widgetData = const {},
    this.isLoading = false,
  });

  ShellState copyWith({ ... });
}
```

### Widget resolver

The shell contains a single `_resolveWidget()` method. All widget-to-state mapping lives here and nowhere else.

```dart
Widget _resolveWidget(ShellState state) {
  switch (state.activeWidget) {
    case ShellWidget.dinnerInvite:
      return DinnerInviteCard(
        invite: DinnerInvite.fromJson(state.widgetData),
        onAccept: _handleAcceptInvite,
        onDecline: _handleDeclineInvite,
      );
    case ShellWidget.pairReveal:
      return PairRevealCard(
        matchDetail: MatchDetail.fromJson(state.widgetData),
        onConfirm: _handleConfirmMatch,
        onDecline: _handleDeclineMatch,
      );
    case ShellWidget.confirmedDinner:
      return ConfirmedDinnerCard(
        matchDetail: MatchDetail.fromJson(state.widgetData),
        onAddToCalendar: _handleAddToCalendar,
        onCheckIn: _handleCheckIn,
        onCancel: _handleLateCancel,
      );
    // ... all other cases
    case ShellWidget.none:
      return const SizedBox.shrink();
  }
}
```

---

## Agent Tool Layer

The Luma agent (Claude) drives the conversation. When the agent needs to take an action or load data, it returns a `tool_use` block. The app handles this by calling the appropriate repository method and either returning the result to the agent or directly updating the shell state.

### Tool definition shape

Every tool lives in `lib/agent/tools/` as its own file.

```dart
// lib/agent/tools/confirm_match_tool.dart

class ConfirmMatchTool {
  static const name = 'confirm_match_guest';

  static Map<String, dynamic> get definition => {
    'name': name,
    'description': 'Confirms that the current user will attend their paired dinner match.',
    'input_schema': {
      'type': 'object',
      'properties': {
        'match_id': {
          'type': 'string',
          'description': 'The UUID of the dinner match to confirm.',
        },
        'user_id': {
          'type': 'string',
          'description': 'The UUID of the user confirming attendance.',
        },
      },
      'required': ['match_id', 'user_id'],
    },
  };

  static Future<Map<String, dynamic>> handle(
    Map<String, dynamic> input,
    MatchRepository matchRepository,
  ) async {
    final result = await matchRepository.confirmMatchGuest(
      matchId: input['match_id'] as String,
      userId: input['user_id'] as String,
    );

    return switch (result) {
      Success(data: final match) => {
        'success': true,
        'match_status': match.status.value,
      },
      Failure(message: final msg) => {
        'success': false,
        'error': msg,
      },
    };
  }
}
```

### Tool registry

```dart
// lib/agent/tool_registry.dart

class ToolRegistry {
  static List<Map<String, dynamic>> get definitions => [
    ConfirmMatchTool.definition,
    DeclineMatchTool.definition,
    GetMatchDetailTool.definition,
    RespondToInviteTool.definition,
    CheckInTool.definition,
    ReportAttendanceTool.definition,
    SubmitFeedbackTool.definition,
    GetCircleDetailTool.definition,
    JoinCircleTool.definition,
    // ...
  ];

  static Future<Map<String, dynamic>> handle(
    String toolName,
    Map<String, dynamic> input,
    RepositoryLocator repositories,
  ) async {
    return switch (toolName) {
      ConfirmMatchTool.name     => ConfirmMatchTool.handle(input, repositories.match),
      DeclineMatchTool.name     => DeclineMatchTool.handle(input, repositories.match),
      GetMatchDetailTool.name   => GetMatchDetailTool.handle(input, repositories.match),
      RespondToInviteTool.name  => RespondToInviteTool.handle(input, repositories.dinner),
      CheckInTool.name          => CheckInTool.handle(input, repositories.match),
      ReportAttendanceTool.name => ReportAttendanceTool.handle(input, repositories.match),
      SubmitFeedbackTool.name   => SubmitFeedbackTool.handle(input, repositories.dinner),
      JoinCircleTool.name       => JoinCircleTool.handle(input, repositories.circle),
      _ => {'error': 'Unknown tool: $toolName'},
    };
  }
}
```

### Agent service — request/response cycle

```dart
// lib/agent/agent_service.dart

class AgentService {
  final AnthropicClient _anthropic;
  final ToolRegistry _registry;
  final RepositoryLocator _repositories;

  // Send a user message and process the full agent response including
  // any tool_use blocks. Returns the final text response and optional
  // shell widget transition instruction.
  Future<AgentResponse> sendMessage({
    required String userMessage,
    required List<ConversationMessage> history,
    Map<String, dynamic>? context,
  }) async {
    final messages = [
      ...history.map((m) => m.toApiMap()),
      {'role': 'user', 'content': userMessage},
    ];

    var response = await _anthropic.messages(
      model: 'claude-sonnet-4-20250514',
      maxTokens: 1000,
      tools: ToolRegistry.definitions,
      messages: messages,
    );

    // Agentic loop — keep running until stop_reason is 'end_turn'
    while (response.stopReason == 'tool_use') {
      final toolUseBlocks = response.content
          .where((b) => b.type == 'tool_use')
          .toList();

      final toolResults = <Map<String, dynamic>>[];

      for (final block in toolUseBlocks) {
        final result = await ToolRegistry.handle(
          block.name,
          block.input,
          _repositories,
        );

        toolResults.add({
          'type': 'tool_result',
          'tool_use_id': block.id,
          'content': jsonEncode(result),
        });
      }

      // Append assistant turn + tool results and continue
      messages.add({'role': 'assistant', 'content': response.content});
      messages.add({'role': 'user', 'content': toolResults});

      response = await _anthropic.messages(
        model: 'claude-sonnet-4-20250514',
        maxTokens: 1000,
        tools: ToolRegistry.definitions,
        messages: messages,
      );
    }

    // Extract text and any widget transition from final response
    return AgentResponse.fromApiResponse(response);
  }
}
```

### Widget transitions from agent

Some tool results carry enough information to update the shell widget directly — the agent does not need to explicitly instruct a transition. The shell observes the result and transitions automatically.

```dart
// lib/agent/agent_response.dart

class AgentResponse {
  final String text;
  final ShellWidget? widgetTransition;
  final Map<String, dynamic>? widgetData;

  const AgentResponse({
    required this.text,
    this.widgetTransition,
    this.widgetData,
  });
}
```

**Rule:** Tool handlers that return data sufficient to render a widget set `widgetTransition` on the response. The shell reads this and calls `_resolveWidget()`. The agent text becomes the Luma message that appears above the widget.

Example: `GetMatchDetailTool` returns a `MatchDetail` with `status = revealed`. The shell sees this, sets `activeWidget = ShellWidget.pairReveal`, and renders `PairRevealCard` beneath the Luma message.

---

## Realtime Subscriptions

All Realtime subscriptions are owned by `RealtimeService`. Screens and widgets never subscribe directly.

### Convention

```dart
// lib/services/realtime_service.dart

class RealtimeService {
  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

  // Subscribe to partner confirmation changes for a given match
  void subscribeToMatchGuests({
    required String matchId,
    required void Function(MatchGuestUpdate) onUpdate,
  }) {
    final channelKey = 'match_guests_$matchId';
    if (_channels.containsKey(channelKey)) return;

    final channel = _client
        .channel(channelKey)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'dinner_match_guests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: (payload) {
            final update = MatchGuestUpdate.fromPayload(payload);
            onUpdate(update);
          },
        )
        .subscribe();

    _channels[channelKey] = channel;
  }

  // Always unsubscribe when the widget or screen is disposed
  void unsubscribe(String channelKey) {
    _channels[channelKey]?.unsubscribe();
    _channels.remove(channelKey);
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
```

### Active subscriptions

| Channel key | Table | Trigger |
|-------------|-------|---------|
| `match_guests_{matchId}` | `dinner_match_guests` | Partner confirms or declines |
| `check_ins_{matchId}` | `dinner_check_ins` | Partner checks in |
| `notifications_{userId}` | `notifications` | New notification arrives |

### Rules
- Subscribe in the shell or screen `initState`, unsubscribe in `dispose`
- Never subscribe inside a `build` method
- Use the `channelKey` pattern to prevent duplicate subscriptions
- `RealtimeService.dispose()` is called when the shell unmounts

---

## Styles

All visual constants live in the style files. Never write inline values.

### app_colors.dart

```dart
// lib/styles/app_colors.dart

class AppColors {
  // Base
  static const Color ink        = Color(0xFF1A1714);
  static const Color inkSoft    = Color(0xFF6B6560);
  static const Color inkFaint   = Color(0xFFB0A89E);
  static const Color cream      = Color(0xFFF2EDE6);
  static const Color creamDark  = Color(0xFFE8E1D8);
  static const Color white      = Color(0xFFFDFAF6);

  // Accent
  static const Color gold       = Color(0xFFB8976A);
  static const Color goldLight  = Color(0xFFD4B48A);

  // Semantic
  static const Color success    = Color(0xFF3D6B4F);
  static const Color error      = Color(0xFFC4513A);
}
```

### dimensions.dart

```dart
// lib/styles/dimensions.dart

class Dimensions {
  // Spacing
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;

  // Border radius
  static const double radiusSm  = 10.0;
  static const double radiusMd  = 16.0;
  static const double radiusLg  = 20.0;
  static const double radiusFull = 999.0;

  // Avatar sizes
  static const double avatarSm  = 28.0;
  static const double avatarMd  = 42.0;
  static const double avatarLg  = 52.0;

  // Card padding
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);

  // Screen horizontal padding
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
}
```

### ❌ Wrong — never do this

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFFB8976A),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    'Confirm',
    style: TextStyle(
      fontSize: 14,
      color: Colors.white,
    ),
  ),
)
```

### ✅ Correct

```dart
Container(
  padding: Dimensions.cardPadding,
  decoration: BoxDecoration(
    color: AppColors.gold,
    borderRadius: BorderRadius.circular(Dimensions.radiusLg),
  ),
  child: Text(
    Strings.confirmCta,
    style: AppTextStyles.buttonPrimary,
  ),
)
```

---

## Strings

All user-facing text lives in `strings.dart`. Never write text inline in a widget.

```dart
// lib/strings.dart

class Strings {
  // Pairing flow
  static const String pairRevealTitle     = 'Your dinner partner is here.';
  static const String pairRevealSubtitle  = 'Confirm to lock it in.';
  static const String confirmCta          = "Confirm I'll be there";
  static const String declineCta          = "Can't make it";
  static const String waitingForPartner   = 'Waiting for your partner to confirm.';
  static const String partnerDeclined     = "Your dinner partner can't make it this time.";
  static const String requeuedMessage     = "You've been re-added to the pool.";

  // Attendance
  static const String attendancePrompt    = 'Did you make it to dinner?';
  static const String attendedYes         = 'Yes, I went';
  static const String attendedNo          = "Couldn't make it";
  static const String flakeWarning        = 'Reporting a no-show will affect your reliability score.';

  // Feedback
  static const String feedbackPrompt      = 'How was the dinner?';
  static const String feedbackSubmitCta   = 'Submit feedback';
  static const String feedbackPhotoPrompt = 'Add a photo to circle memories?';

  // Circles
  static const String circleFoundTitle    = 'Found it. Want to join?';
  static const String joinCircleCta       = 'Join this circle →';
  static const String notNowCta           = 'Not now';
  static const String createCircleCta     = 'Create Circle →';
  static const String copyCodeCta         = 'Copy Code';
  static const String shareBadgeCta       = 'Share Badge ↗';
}
```

### ❌ Wrong

```dart
Text("Your dinner partner can't make it this time.")
```

### ✅ Correct

```dart
Text(Strings.partnerDeclined)
```

---

## Logging

Never use `debugPrint`. Always use `AppLogger`.

```dart
// Usage examples

AppLogger.info('Match confirmed', data: {'matchId': matchId});
AppLogger.warning('Reveal_at is null for match', data: {'matchId': matchId});
AppLogger.error('Failed to confirm match', error: e, stackTrace: st);
```

### ❌ Wrong

```dart
debugPrint('Match confirmed: $matchId');
print('error: $e');
```

### ✅ Correct

```dart
AppLogger.info('Match confirmed', data: {'matchId': matchId});
AppLogger.error('Failed to confirm match', error: e);
```

---

## Error Handling

- Repository methods return `Result<T>` — never throw to the UI layer
- Widgets switch on `Result` and show appropriate UI for `Failure` cases
- All `catch` blocks log via `AppLogger` before returning `Failure`
- Never swallow errors silently

```dart
// In a widget / shell handler
final result = await _matchRepository.confirmMatchGuest(
  matchId: matchId,
  userId: userId,
);

switch (result) {
  case Success(data: final match):
    // update shell state
  case Failure(message: final msg):
    // show Luma error message in feed
    AppLogger.error('Confirm match failed', error: msg);
}
```

---

## Routing

Only true screens have named routes. Pairing flow states, dinner flow states, and any widget injected by the agent are **not** routes.

```dart
// lib/router.dart

class AppRouter {
  static const String shell            = '/';
  static const String circleDetail     = '/circle';
  static const String circleDetailAdmin = '/circle/admin';
  static const String profile          = '/profile';
  static const String notifications    = '/notifications';
  static const String settings         = '/settings';
}
```

Deep links from FCM push notifications resolve to a **shell state**, not a route. The notification router parses the `notification_type` and `data` payload, sets the appropriate `ShellWidget` and `widgetData`, and navigates to the shell — which renders the correct widget immediately on arrival.

```dart
// lib/services/fcm_service.dart

ShellWidgetConfig? resolveNotification(RemoteMessage message) {
  final type = message.data['notification_type'] as String?;
  final data = message.data;

  return switch (type) {
    'dinner_invite'    => ShellWidgetConfig(ShellWidget.dinnerInvite,    data),
    'dinner_paired'    => ShellWidgetConfig(ShellWidget.pairReveal,      data),
    'match_confirmed'  => ShellWidgetConfig(ShellWidget.confirmedDinner, data),
    'match_cancelled'  => ShellWidgetConfig(ShellWidget.partnerDeclined, data),
    'attendance_reminder' => ShellWidgetConfig(ShellWidget.attendanceReport, data),
    'feedback_prompt'  => ShellWidgetConfig(ShellWidget.feedback,        data),
    _                  => null,
  };
}
```

---

## Adding a New Feature — Checklist

1. Read `architecture.md` and `agents.md` before writing anything
2. Create the model in `lib/models/`
3. Create or extend the repository in `lib/repositories/`
4. If agent-callable, create the tool in `lib/agent/tools/` and register it in `tool_registry.dart`
5. If it renders a widget in the shell, add the widget to `lib/widgets/conversation/`, add the `ShellWidget` enum value, and add the case to `_resolveWidget()`
6. If it needs a Realtime subscription, add it to `realtime_service.dart`
7. Add all new strings to `strings.dart`
8. Add all new colors or dimensions to the style files
9. Reference mockups in `mockups/` before building any UI
10. Update `feature_list.md` and `progress.txt` when done