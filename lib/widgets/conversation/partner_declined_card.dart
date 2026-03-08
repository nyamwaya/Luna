import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../shared/pairing_ui_kit.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PairingInlineBanner(
          text: 'Match with Priya cancelled\nShe opted out of this round. This won\'t affect your flake score — you confirmed your side.',
          icon: Icons.reply,
          backgroundColor: AppColors.errorSurface,
          borderColor: AppColors.errorBorder,
          foregroundColor: AppColors.ink,
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('BACK IN THE POOL', style: AppTextStyles.eyebrow),
              const SizedBox(height: Dimensions.md),
              Text(
                '${matchDetail.event.title} · ${matchDetail.circle?.name ?? Strings.valuePending}',
                style: AppTextStyles.panelTitle,
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                DateTimeFormatter.short(matchDetail.event.scheduledDate),
                style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Dimensions.lg),
              const PairingProgressBar(progress: 0.4),
              const SizedBox(height: Dimensions.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      Strings.lookingForNewPair,
                      style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                  Text(
                    Strings.unmatchedCountLabel,
                    style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: PairingPillButton(
                label: Strings.skipRoundCta,
                tone: PairingButtonTone.outlineLight,
                onPressed: onSkip,
              ),
            ),
            const SizedBox(width: Dimensions.md),
            Expanded(
              child: PairingPillButton(
                label: 'Keep me in →',
                tone: PairingButtonTone.dark,
                onPressed: onKeepMeIn,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
