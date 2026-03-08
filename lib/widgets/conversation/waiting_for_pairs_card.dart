import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/guest_dinner_event_view.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../luma_message.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the waiting-for-pairs state within the conversation shell.
class WaitingForPairsCard extends StatelessWidget {
  /// Creates a waiting-for-pairs card.
  const WaitingForPairsCard({required this.view, super.key});

  /// The guest event payload to display.
  final GuestDinnerEventView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PairingPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${view.event.title.toUpperCase()} · ${(view.event.circleName ?? Strings.valuePending).toUpperCase()}',
                style: AppTextStyles.eyebrow,
              ),
              const SizedBox(height: Dimensions.md),
              Text(view.event.venue ?? Strings.valuePending, style: AppTextStyles.panelTitle),
              const SizedBox(height: Dimensions.xs),
              Text(
                DateTimeFormatter.short(view.event.scheduledDate),
                style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Dimensions.lg),
              const PairingProgressBar(progress: 0.68),
              const SizedBox(height: Dimensions.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${view.invite.acceptedCount} ${Strings.acceptedShortLabel}',
                      style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                  Text(
                    'Pairs on Mar 12',
                    style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        const LumaMessage(
          text: 'While you wait — Marcus, Dani, and Priya haven\'t confirmed yet. Want to nudge them?',
        ),
        const SizedBox(height: Dimensions.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: PairingPillButton(
                label: Strings.nudgeThemCta,
                tone: PairingButtonTone.outlineLight,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: Dimensions.md),
            Expanded(
              child: PairingPillButton(
                label: Strings.notNowCtaPlain,
                tone: PairingButtonTone.outlineLight,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
