import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the pair reveal state within the conversation shell.
class PairRevealCard extends StatelessWidget {
  /// Creates a pair reveal card.
  const PairRevealCard({
    required this.matchDetail,
    this.onConfirm,
    this.onDecline,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user confirms attendance.
  final VoidCallback? onConfirm;

  /// Called when the user declines the match.
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final MatchPartnerDetail? partner = matchDetail.partner;

    return ConversationCard(
      title: Strings.pairRevealTitle,
      subtitle: Strings.pairRevealSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.confirmCta, onPressed: onConfirm),
          SecondaryConversationButton(label: Strings.declineCta, onPressed: onDecline),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(label: Strings.partnerLabel, value: partner?.profile.firstName ?? Strings.valuePending),
          LabeledValue(
            label: Strings.occupationLabel,
            value: partner?.profile.occupation ?? Strings.valuePending,
          ),
          LabeledValue(
            label: Strings.sharedInterestsLabel,
            value: partner == null || partner.sharedInterests.isEmpty
                ? Strings.valuePending
                : partner.sharedInterests.join(', '),
          ),
          LabeledValue(label: Strings.venueLabel, value: matchDetail.event.venue ?? Strings.valuePending),
          LabeledValue(
            label: Strings.whenLabel,
            value: DateTimeFormatter.short(matchDetail.event.scheduledDate),
          ),
        ],
      ),
    );
  }
}
