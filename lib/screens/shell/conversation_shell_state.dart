import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation_message.dart';

/// Identifies the active contextual widget rendered in the shell.
enum ShellWidget {
  /// No contextual widget is currently active.
  none,

  /// Home dashboard state.
  homeDashboard,

  /// Dinner invite prompt.
  dinnerInvite,

  /// Waiting for pairs state.
  waitingForPairs,

  /// Pair reveal state.
  pairReveal,

  /// Waiting for partner confirmation state.
  waitingForPartner,

  /// Partner declined state.
  partnerDeclined,

  /// Confirmed dinner detail state.
  confirmedDinner,

  /// Day-of check-in state.
  checkIn,

  /// Attendance reporting state.
  attendanceReport,

  /// Post-dinner feedback state.
  feedback,
}

/// Defines a shell widget transition with associated payload data.
class ShellWidgetConfig {
  /// Creates a shell widget configuration.
  const ShellWidgetConfig(this.widget, this.data);

  /// The widget to render.
  final ShellWidget widget;

  /// The serialized widget payload.
  final Map<String, dynamic> data;
}

/// Represents the current conversation shell state.
class ShellState {
  /// Creates a shell state.
  const ShellState({
    this.messages = const <ConversationMessage>[],
    this.activeWidget = ShellWidget.none,
    this.widgetData = const <String, dynamic>{},
    this.isLoading = false,
  });

  /// Creates the default shell state.
  factory ShellState.initial() {
    return const ShellState();
  }

  /// The conversation feed messages.
  final List<ConversationMessage> messages;

  /// The current contextual widget in view.
  final ShellWidget activeWidget;

  /// The payload for the active contextual widget.
  final Map<String, dynamic> widgetData;

  /// Whether the shell is processing an action.
  final bool isLoading;

  /// Creates a modified copy of the state.
  ShellState copyWith({
    List<ConversationMessage>? messages,
    ShellWidget? activeWidget,
    Map<String, dynamic>? widgetData,
    bool? isLoading,
  }) {
    return ShellState(
      messages: messages ?? this.messages,
      activeWidget: activeWidget ?? this.activeWidget,
      widgetData: widgetData ?? this.widgetData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Riverpod provider for the conversation shell controller.
final conversationShellControllerProvider =
    NotifierProvider<ConversationShellController, ShellState>(
  ConversationShellController.new,
);

/// Manages shell messages, widget transitions, and loading state.
class ConversationShellController extends Notifier<ShellState> {
  /// Initializes the shell state.
  @override
  ShellState build() {
    return ShellState.initial();
  }

  /// Adds a new Luma-authored message to the feed.
  void addLumaMessage(String text, {Map<String, dynamic> metadata = const <String, dynamic>{}}) {
    state = state.copyWith(
      messages: <ConversationMessage>[
        ...state.messages,
        ConversationMessage.luma(text: text, metadata: metadata),
      ],
    );
  }

  /// Adds a new user-authored message to the feed.
  void addUserMessage(String text, {Map<String, dynamic> metadata = const <String, dynamic>{}}) {
    state = state.copyWith(
      messages: <ConversationMessage>[
        ...state.messages,
        ConversationMessage.user(text: text, metadata: metadata),
      ],
    );
  }

  /// Replaces the current conversation feed with a new set of messages.
  void replaceMessages(List<ConversationMessage> messages) {
    state = state.copyWith(messages: messages);
  }

  /// Sets the current loading state.
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Activates a contextual widget with serialized data.
  void setActiveWidget(ShellWidget widget, Map<String, dynamic> data) {
    state = state.copyWith(activeWidget: widget, widgetData: data);
  }

  /// Applies a contextual widget configuration.
  void showWidgetConfig(ShellWidgetConfig config) {
    setActiveWidget(config.widget, config.data);
  }

  /// Clears the active contextual widget.
  void clearActiveWidget() {
    state = state.copyWith(
      activeWidget: ShellWidget.none,
      widgetData: const <String, dynamic>{},
    );
  }
}
