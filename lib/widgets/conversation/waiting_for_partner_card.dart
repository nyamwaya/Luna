import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../shared/pairing_ui_kit.dart';

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
    return PairingMatchCard(
      eyebrow: '✦ YOUR MATCH',
      name: matchDetail.partner?.profile.firstName ?? Strings.valuePending,
      subtitle: matchDetail.partner?.profile.occupation ?? Strings.valuePending,
      locationTitle: matchDetail.event.venue ?? Strings.valuePending,
      locationSubtitle: DateTimeFormatter.short(matchDetail.event.scheduledDate),
      interests: matchDetail.partner?.sharedInterests ?? const <String>[Strings.valuePending],
      avatarLabel: (matchDetail.partner?.profile.firstName ?? 'P').substring(0, 1).toUpperCase(),
      topNotice: const PairingInlineBanner(
        text: Strings.pendingConfirmationLabel,
        backgroundColor: AppColors.shell,
        borderColor: AppColors.cardBorder,
        foregroundColor: AppColors.gold,
      ),
      footer: Row(
        children: <Widget>[
          Expanded(
            child: PairingPillButton(
              label: Strings.cancelSpotCta,
              tone: PairingButtonTone.outlineDark,
              onPressed: onCancel,
            ),
          ),
          const SizedBox(width: Dimensions.md),
          const Spacer(),
        ],
      ),
    );
  }
}
