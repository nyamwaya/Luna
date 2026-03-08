import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../luma_message.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the attendance report prompt within the conversation shell.
class AttendanceReportCard extends StatelessWidget {
  /// Creates an attendance report card.
  const AttendanceReportCard({
    required this.matchDetail,
    this.onReport,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user chooses an attendance value.
  final ValueChanged<bool>? onReport;

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
                '${matchDetail.circle?.name ?? Strings.valuePending} · ${matchDetail.event.title}'.toUpperCase(),
                style: AppTextStyles.eyebrow.copyWith(color: AppColors.inkFaint),
              ),
              const SizedBox(height: Dimensions.md),
              Text(
                matchDetail.event.venue ?? Strings.valuePending,
                style: AppTextStyles.panelTitle,
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                'With ${matchDetail.partner?.profile.firstName ?? Strings.valuePending} · Thursday, Mar 19',
                style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Dimensions.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PairingPillButton(
                      label: '✓${Strings.attendedYes}',
                      tone: PairingButtonTone.dark,
                      onPressed: onReport == null ? null : () => onReport!(true),
                    ),
                  ),
                  const SizedBox(width: Dimensions.md),
                  Expanded(
                    child: PairingPillButton(
                      label: Strings.attendedNo,
                      tone: PairingButtonTone.muted,
                      onPressed: onReport == null ? null : () => onReport!(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        const PairingInlineBanner(
          text: Strings.noShowImpactLabel,
          icon: Icons.warning_amber_rounded,
          backgroundColor: AppColors.errorSurface,
          borderColor: AppColors.errorBorder,
          foregroundColor: AppColors.error,
        ),
        const SizedBox(height: Dimensions.lg),
        const LumaMessage(text: Strings.attendanceWindowMessage),
      ],
    );
  }
}
