import '../screens/shell/conversation_shell_state.dart';

/// Resolves notification payloads into shell widget transitions.
abstract final class NotificationRouter {
  /// Returns the shell widget configuration for a notification type.
  static ShellWidgetConfig? resolve({
    required String? notificationType,
    required Map<String, dynamic> data,
  }) {
    return switch (notificationType) {
      'dinner_invite' => ShellWidgetConfig(ShellWidget.dinnerInvite, data),
      'dinner_pending' => ShellWidgetConfig(ShellWidget.waitingForPairs, data),
      'dinner_paired' => ShellWidgetConfig(ShellWidget.pairReveal, data),
      'match_confirmed' => ShellWidgetConfig(ShellWidget.confirmedDinner, data),
      'match_cancelled' => ShellWidgetConfig(ShellWidget.partnerDeclined, data),
      'attendance_reminder' => ShellWidgetConfig(ShellWidget.attendanceReport, data),
      'feedback_prompt' => ShellWidgetConfig(ShellWidget.feedback, data),
      _ => null,
    };
  }
}
