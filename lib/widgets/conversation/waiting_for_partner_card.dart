import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

/// Displays the waiting-for-partner-confirmation state.
class WaitingForPartnerCard extends StatelessWidget {
  /// Creates a waiting-for-partner card.
  const WaitingForPartnerCard({
    required this.matchDetail,
    this.onCancel,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user cancels their spot.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ConversationCard(
      title: Strings.waitingForPartner,
      subtitle: Strings.waitingForPartnerSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          SecondaryConversationButton(label: Strings.cancelSpotCta, onPressed: onCancel),
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
            label: Strings.confirmationStatusLabel,
            value: Strings.partnerPendingStatus,
          ),
        ],
      ),
    );
  }
}
