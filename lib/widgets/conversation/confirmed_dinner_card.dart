import 'package:flutter/material.dart';

import '../../core/date_time_formatter.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the confirmed dinner detail state within the conversation shell.
class ConfirmedDinnerCard extends StatelessWidget {
  /// Creates a confirmed dinner card.
  const ConfirmedDinnerCard({
    required this.matchDetail,
    this.onAddToCalendar,
    this.onCheckIn,
    this.onCancel,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user taps add to calendar.
  final VoidCallback? onAddToCalendar;

  /// Called when the user taps check in.
  final VoidCallback? onCheckIn;

  /// Called when the user taps cancel.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PairingPanel(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.successDark, AppColors.sageDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: Dimensions.sm),
                decoration: BoxDecoration(
                  color: AppColors.successPill,
                  borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                ),
                child: Text(
                  Strings.confirmedBadge,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.lg),
              Text(
                '${matchDetail.circle?.name ?? Strings.valuePending} · ${matchDetail.event.title}',
                style: AppTextStyles.body.copyWith(color: AppColors.creamDark),
              ),
              const SizedBox(height: Dimensions.sm),
              Text(
                DateTimeFormatter.short(matchDetail.event.scheduledDate),
                style: AppTextStyles.panelTitleOnDark,
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                '7:30 PM · 2 ${Strings.guestCountShortLabel}',
                style: AppTextStyles.body.copyWith(color: AppColors.creamDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 136,
                decoration: const BoxDecoration(
                  color: Color(0xFFC8D8C0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${Strings.mapPreviewLabel}\n📍',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.inkFaint,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Dimensions.lg),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            matchDetail.event.venue ?? Strings.valuePending,
                            style: AppTextStyles.panelTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: Dimensions.xs),
                          Text(
                            matchDetail.event.venueAddress ?? Strings.valuePending,
                            style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.md),
                    PairingPillButton(
                      label: Strings.getDirectionsCta,
                      tone: PairingButtonTone.outlineLight,
                      expanded: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPanel(
          child: Row(
            children: <Widget>[
              PairingInitialAvatar(
                label: (matchDetail.partner?.profile.firstName ?? 'P').substring(0, 1).toUpperCase(),
                size: Dimensions.avatarXl,
                backgroundColor: AppColors.sage,
              ),
              const SizedBox(width: Dimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${matchDetail.partner?.profile.firstName ?? Strings.valuePending} ${matchDetail.partner?.profile.lastName ?? ''}'.trim(),
                      style: AppTextStyles.panelTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      matchDetail.partner?.profile.occupation ?? Strings.valuePending,
                      style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: Dimensions.sm),
                    Wrap(
                      spacing: Dimensions.sm,
                      runSpacing: Dimensions.sm,
                      children: (matchDetail.partner?.sharedInterests ?? const <String>[Strings.valuePending])
                          .map(
                            (String interest) => PairingTagChip(
                              label: interest,
                              isSelected: false,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        Row(
          children: <Widget>[
            PairingActionTile(
              label: 'Add to\nCalendar',
              icon: Icons.calendar_month_rounded,
              onTap: onAddToCalendar,
            ),
            const SizedBox(width: Dimensions.sm),
            PairingActionTile(
              label: 'Check In',
              subtitle: Strings.checkInOpensSoon,
              icon: Icons.location_pin,
              foregroundColor: AppColors.inkFaint,
              onTap: onCheckIn,
            ),
            const SizedBox(width: Dimensions.sm),
            PairingActionTile(
              label: Strings.cantGoCta,
              icon: Icons.close_rounded,
              foregroundColor: AppColors.error,
              onTap: onCancel,
            ),
          ],
        ),
      ],
    );
  }
}
