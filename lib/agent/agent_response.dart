import '../screens/shell/conversation_shell_state.dart';

/// Represents the result of a single agent turn.
class AgentResponse {
  /// Creates an agent response.
  const AgentResponse({
    required this.text,
    this.widgetTransition,
    this.widgetData,
  });

  /// The assistant text response.
  final String text;

  /// The optional shell widget transition.
  final ShellWidget? widgetTransition;

  /// The serialized payload for the widget transition.
  final Map<String, dynamic>? widgetData;

  /// Converts the response to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'text': text,
      'widget_transition': widgetTransition?.name,
      'widget_data': widgetData,
    };
  }
}
