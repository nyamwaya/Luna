import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the confirmed dinner detail state within the conversation shell.
class ConfirmedDinnerCard extends StatelessWidget {
  /// Creates a confirmed dinner card.
  const ConfirmedDinnerCard({
    required this.matchDetail,
    this.onAddToCalendar,
    this.onCheckIn,
    this.onCancel,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user taps add to calendar.
  final VoidCallback? onAddToCalendar;

  /// Called when the user taps check in.
  final VoidCallback? onCheckIn;

  /// Called when the user taps cancel.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.confirmedDinnerTitle,
      subtitle: Strings.confirmedDinnerSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.addToCalendarCta, onPressed: onAddToCalendar),
          SecondaryConversationButton(label: Strings.checkInCta, onPressed: onCheckIn),
          SecondaryConversationButton(label: Strings.cantGoCta, onPressed: onCancel),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(label: Strings.eventLabel, value: matchDetail.event.title),
          LabeledValue(
            label: Strings.whenLabel,
            value: DateTimeFormatter.short(matchDetail.event.scheduledDate),
          ),
          LabeledValue(label: Strings.whereLabel, value: matchDetail.event.venue ?? Strings.valuePending),
          LabeledValue(
            label: Strings.partnerLabel,
            value: matchDetail.partner?.profile.firstName ?? Strings.valuePending,
          ),
        ],
      ),
    );
  }
}
