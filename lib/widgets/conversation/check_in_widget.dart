import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../luma_message.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the day-of check-in state within the conversation shell.
class CheckInWidget extends StatelessWidget {
  /// Creates a check-in widget.
  const CheckInWidget({
    required this.matchDetail,
    this.onCheckIn,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user taps check in.
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PairingPanel(
          backgroundColor: AppColors.dark,
          child: Column(
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('📍', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: Dimensions.lg),
              Text(
                matchDetail.event.venue ?? Strings.valuePending,
                style: AppTextStyles.panelTitleOnDark,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                matchDetail.event.venueAddress ?? Strings.valuePending,
                style: AppTextStyles.body.copyWith(color: AppColors.creamDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.lg),
              PairingPillButton(
                label: Strings.withinRangeStatus,
                tone: PairingButtonTone.gold,
                expanded: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPanel(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      matchDetail.partner?.profile.firstName ?? Strings.valuePending,
                      style: AppTextStyles.panelTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      Strings.checkInStatusLabel,
                      style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: Dimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                ),
                child: Text(
                  matchDetail.partner?.checkedIn == true ? Strings.partnerCheckedInStatus : Strings.notYetStatus,
                  style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPillButton(
          label: 'Check in now →',
          tone: PairingButtonTone.gold,
          onPressed: onCheckIn,
        ),
        const SizedBox(height: Dimensions.lg),
        const LumaMessage(
          text: 'After dinner, I\'ll ask if you both made it. Enjoy your evening. 🥂',
        ),
      ],
    );
  }
}
