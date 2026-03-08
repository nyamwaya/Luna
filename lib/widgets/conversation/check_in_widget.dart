import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the day-of check-in state within the conversation shell.
class CheckInWidget extends StatelessWidget {
  /// Creates a check-in widget.
  const CheckInWidget({
    required this.matchDetail,
    this.onCheckIn,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user taps check in.
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.checkInTitle,
      subtitle: Strings.checkInSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.checkInCta, onPressed: onCheckIn),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(
            label: Strings.windowOpensLabel,
            value: DateTimeFormatter.short(matchDetail.event.checkinWindowOpensAt),
          ),
          LabeledValue(
            label: Strings.windowClosesLabel,
            value: DateTimeFormatter.short(matchDetail.event.checkinWindowClosesAt),
          ),
          LabeledValue(
            label: Strings.partnerCheckInLabel,
            value: matchDetail.partner?.checkedIn == true
                ? Strings.partnerCheckedInStatus
                : Strings.partnerPendingStatus,
          ),
        ],
      ),
    );
  }
}
