import '../repositories/repository_locator.dart';
import 'tools/check_in_tool.dart';
import 'tools/confirm_match_tool.dart';
import 'tools/decline_match_tool.dart';
import 'tools/get_dinner_event_for_guest_tool.dart';
import 'tools/get_dinner_invite_tool.dart';
import 'tools/get_match_detail_tool.dart';
import 'tools/report_attendance_tool.dart';
import 'tools/respond_to_invite_tool.dart';
import 'tools/submit_feedback_tool.dart';

/// Registers tool definitions and dispatches tool handlers.
abstract final class ToolRegistry {
  /// The set of tool definitions exposed to the agent.
  static List<Map<String, dynamic>> get definitions {
    return <Map<String, dynamic>>[
      GetDinnerInviteTool.definition,
      RespondToInviteTool.definition,
      GetDinnerEventForGuestTool.definition,
      GetMatchDetailTool.definition,
      ConfirmMatchTool.definition,
      DeclineMatchTool.definition,
      CheckInTool.definition,
      ReportAttendanceTool.definition,
      SubmitFeedbackTool.definition,
    ];
  }

  /// Dispatches a tool call to the appropriate handler.
  static Future<Map<String, dynamic>> handle(
    String toolName,
    Map<String, dynamic> input,
    RepositoryLocator repositories,
  ) {
    return switch (toolName) {
      GetDinnerInviteTool.name => GetDinnerInviteTool.handle(input, repositories.dinner),
      RespondToInviteTool.name => RespondToInviteTool.handle(input, repositories.dinner),
      GetDinnerEventForGuestTool.name =>
        GetDinnerEventForGuestTool.handle(input, repositories.dinner),
      GetMatchDetailTool.name => GetMatchDetailTool.handle(input, repositories.match),
      ConfirmMatchTool.name => ConfirmMatchTool.handle(input, repositories.match),
      DeclineMatchTool.name => DeclineMatchTool.handle(input, repositories.match),
      CheckInTool.name => CheckInTool.handle(input, repositories.match),
      ReportAttendanceTool.name => ReportAttendanceTool.handle(input, repositories.match),
      SubmitFeedbackTool.name => SubmitFeedbackTool.handle(input, repositories.dinner),
      _ => Future<Map<String, dynamic>>.value(
          <String, dynamic>{'success': false, 'error': 'Unknown tool: $toolName'},
        ),
    };
  }
}
