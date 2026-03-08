import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the partner-declined state within the conversation shell.
class PartnerDeclinedCard extends StatelessWidget {
  /// Creates a partner-declined card.
  const PartnerDeclinedCard({
    required this.matchDetail,
    this.onKeepMeIn,
    this.onSkip,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user wants to stay in the pool.
  final VoidCallback? onKeepMeIn;

  /// Called when the user wants to skip the round.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.partnerDeclined,
      subtitle: Strings.partnerDeclinedSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.keepMeInCta, onPressed: onKeepMeIn),
          SecondaryConversationButton(label: Strings.skipRoundCta, onPressed: onSkip),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(
            label: Strings.partnerLabel,
            value: matchDetail.partner?.profile.firstName ?? Strings.valuePending,
          ),
          LabeledValue(
            label: Strings.policyLabel,
            value: matchDetail.event.cancellationPolicy ?? Strings.valuePending,
          ),
        ],
      ),
    );
  }
}
