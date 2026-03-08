import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/dinner_invite.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the dinner invite prompt within the conversation shell.
class DinnerInviteCard extends StatelessWidget {
  /// Creates a dinner invite card.
  const DinnerInviteCard({
    required this.invite,
    this.onAccept,
    this.onDecline,
    super.key,
  });

  /// The invite payload to display.
  final DinnerInvite invite;

  /// Called when the user accepts the invite.
  final VoidCallback? onAccept;

  /// Called when the user declines the invite.
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.dinnerInviteTitle,
      subtitle: Strings.dinnerInviteSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.acceptInviteCta, onPressed: onAccept),
          SecondaryConversationButton(label: Strings.declineInviteCta, onPressed: onDecline),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(label: Strings.eventLabel, value: invite.eventTitle ?? Strings.valuePending),
          LabeledValue(
            label: Strings.whenLabel,
            value: DateTimeFormatter.short(invite.scheduledDate),
          ),
          LabeledValue(label: Strings.whereLabel, value: invite.venue ?? Strings.valuePending),
          LabeledValue(label: Strings.circleLabel, value: invite.circleName ?? Strings.valuePending),
          LabeledValue(
            label: Strings.acceptedCountLabel,
            value: '${invite.acceptedCount}',
          ),
        ],
      ),
    );
  }
}
