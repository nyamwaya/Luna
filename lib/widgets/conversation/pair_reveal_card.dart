import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/dimensions.dart';
import '../shared/pairing_ui_kit.dart';

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
    final List<String> interests = partner == null || partner.sharedInterests.isEmpty
        ? const <String>[Strings.valuePending]
        : partner.sharedInterests;

    return PairingMatchCard(
      eyebrow: '✦ YOUR MATCH',
      name: partner?.profile.firstName ?? Strings.valuePending,
      subtitle: partner?.profile.occupation ?? Strings.valuePending,
      locationTitle: matchDetail.event.venue ?? Strings.valuePending,
      locationSubtitle: DateTimeFormatter.short(matchDetail.event.scheduledDate),
      interests: interests,
      avatarLabel: (partner?.profile.firstName ?? 'P').substring(0, 1).toUpperCase(),
      footer: Row(
        children: <Widget>[
          Expanded(
            child: PairingPillButton(
              label: Strings.confirmCta,
              tone: PairingButtonTone.gold,
              onPressed: onConfirm,
            ),
          ),
          const SizedBox(width: Dimensions.md),
          Expanded(
            child: PairingPillButton(
              label: Strings.declineCta,
              tone: PairingButtonTone.outlineDark,
              onPressed: onDecline,
            ),
          ),
        ],
      ),
    );
  }
}
