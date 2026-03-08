import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';

/// Displays the attendance report prompt within the conversation shell.
class AttendanceReportCard extends StatelessWidget {
  /// Creates an attendance report card.
  const AttendanceReportCard({
    required this.matchDetail,
    this.onReport,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user chooses an attendance value.
  final ValueChanged<bool>? onReport;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.attendancePrompt,
      subtitle: Strings.flakeWarning,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(
            label: Strings.attendedYes,
            onPressed: onReport == null ? null : () => onReport!(true),
          ),
          SecondaryConversationButton(
            label: Strings.attendedNo,
            onPressed: onReport == null ? null : () => onReport!(false),
          ),
        ],
      ),
    );
  }
}
