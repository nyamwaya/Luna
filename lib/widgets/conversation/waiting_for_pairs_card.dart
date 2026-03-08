import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/guest_dinner_event_view.dart';
import '../../strings.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the waiting-for-pairs state within the conversation shell.
class WaitingForPairsCard extends StatelessWidget {
  /// Creates a waiting-for-pairs card.
  const WaitingForPairsCard({required this.view, super.key});

  /// The guest event payload to display.
  final GuestDinnerEventView view;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.waitingForPairsTitle,
      subtitle: Strings.waitingForPairsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(label: Strings.eventLabel, value: view.event.title),
          LabeledValue(
            label: Strings.whenLabel,
            value: DateTimeFormatter.short(view.event.scheduledDate),
          ),
          LabeledValue(label: Strings.whereLabel, value: view.event.venue ?? Strings.valuePending),
          LabeledValue(
            label: Strings.revealAtLabel,
            value: DateTimeFormatter.short(view.match?.revealAt),
          ),
        ],
      ),
    );
  }
}
