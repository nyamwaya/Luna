import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/dinner_invite.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the dinner invite prompt within the conversation shell.
class DinnerInviteCard extends StatelessWidget {
  /// Creates a dinner invite card.
  const DinnerInviteCard({
    required this.invite,
    this.onAccept,
    this.onDecline,
    super.key,
  });

  /// The invite payload to display.
  final DinnerInvite invite;

  /// Called when the user accepts the invite.
  final VoidCallback? onAccept;

  /// Called when the user declines the invite.
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final List<String> avatarLabels = invite.acceptedAvatars
        .map(
          (avatar) => avatar.firstName.isEmpty ? '?' : avatar.firstName.substring(0, 1).toUpperCase(),
        )
        .take(4)
        .toList();

    return PairingPanel(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.white,
      radius: 30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.bronzeDark, AppColors.bronze],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (invite.circleName ?? Strings.valuePending).toUpperCase(),
                  style: AppTextStyles.eyebrow.copyWith(color: AppColors.goldLight),
                ),
                const SizedBox(height: Dimensions.md),
                Text(
                  invite.eventTitle ?? Strings.valuePending,
                  style: AppTextStyles.panelTitleOnDark.copyWith(fontSize: 20),
                ),
                const SizedBox(height: Dimensions.sm),
                Text(
                  '${DateTimeFormatter.short(invite.scheduledDate)} · ${invite.venue ?? Strings.valuePending}',
                  style: AppTextStyles.body.copyWith(color: AppColors.cream),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Dimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ...avatarLabels.map(
                      (String label) => Padding(
                        padding: const EdgeInsets.only(right: Dimensions.xs),
                        child: PairingInitialAvatar(
                          label: label,
                          size: Dimensions.avatarMd,
                          backgroundColor: _avatarColorFor(label),
                        ),
                      ),
                    ),
                    if (invite.acceptedCount > avatarLabels.length)
                      Padding(
                        padding: const EdgeInsets.only(right: Dimensions.sm),
                        child: PairingInitialAvatar(
                          label: '+',
                          size: Dimensions.avatarMd,
                          backgroundColor: AppColors.gold,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        '${invite.acceptedCount} ${Strings.acceptedShortLabel} so far',
                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PairingPillButton(
                        label: Strings.acceptInviteCta,
                        tone: PairingButtonTone.dark,
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: onAccept,
                      ),
                    ),
                    const SizedBox(width: Dimensions.md),
                    Expanded(
                      child: PairingPillButton(
                        label: Strings.declineInviteCta,
                        tone: PairingButtonTone.outlineLight,
                        onPressed: onDecline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _avatarColorFor(String label) {
    return switch (label) {
      'M' => const Color(0xFF7BA786),
      'D' => const Color(0xFFA88D79),
      'P' => const Color(0xFF7C8AA8),
      _ => const Color(0xFF9E7890),
    };
  }
}
