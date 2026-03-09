import 'package:flutter/material.dart';

import '../../models/home/home_dashboard_view.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../shared/pairing_ui_kit.dart';

/// Home dashboard card rendered inside the conversation shell feed.
class HomeDashboardCard extends StatelessWidget {
  /// Creates the home dashboard card.
  const HomeDashboardCard({
    required this.view,
    required this.onOpenConfirmedDinner,
    required this.onRequestSeat,
    required this.onTapFindDinner,
    required this.onTapMyCircles,
    required this.onTapStartCircle,
    required this.onTapMyProfile,
    super.key,
  });

  /// The dashboard payload.
  final HomeDashboardView view;

  /// Opens details for the user's confirmed dinner.
  final VoidCallback onOpenConfirmedDinner;

  /// Handles requesting an open seat.
  final ValueChanged<HomeOpenSeat> onRequestSeat;

  /// Handles tapping the Find a Dinner action.
  final VoidCallback onTapFindDinner;

  /// Handles tapping the My Circles action.
  final VoidCallback onTapMyCircles;

  /// Handles tapping the Start a Circle action.
  final VoidCallback onTapStartCircle;

  /// Handles tapping the My Profile action.
  final VoidCallback onTapMyProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (view.confirmedDinner != null) ...<Widget>[
          _ConfirmedDinnerCard(
            dinner: view.confirmedDinner!,
            onDetailsTap: onOpenConfirmedDinner,
          ),
          const SizedBox(height: Dimensions.md),
        ],
        _SectionCard(
          title: Strings.homeUpcomingDinnersTitle,
          child: view.upcomingDinners.isEmpty
              ? const _EmptySectionState(label: Strings.homeNoUpcomingDinners)
              : Column(
                  children: view.upcomingDinners
                      .map(
                        (HomeUpcomingDinner dinner) => Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.sm),
                          child: _UpcomingDinnerRow(dinner: dinner),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: Dimensions.md),
        _SectionCard(
          title: Strings.homeCirclesTitle,
          child: view.circles.isEmpty
              ? const _EmptySectionState(label: Strings.homeNoCircles)
              : Column(
                  children: view.circles
                      .map(
                        (HomeCircleSummary circle) => Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.sm),
                          child: _CircleSummaryRow(circle: circle),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: Dimensions.md),
        PairingInlineBanner(
          text: view.openSeatsPrompt,
          backgroundColor: AppColors.white,
          borderColor: AppColors.cardBorder,
          foregroundColor: AppColors.ink,
        ),
        if (view.openSeats.isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.md),
          SizedBox(
            height: Dimensions.homeSeatCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: view.openSeats.length,
              separatorBuilder: (_, __) => const SizedBox(width: Dimensions.sm),
              itemBuilder: (BuildContext context, int index) {
                final HomeOpenSeat seat = view.openSeats[index];
                return _OpenSeatCard(
                  seat: seat,
                  onRequestSeat: () => onRequestSeat(seat),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: Dimensions.md),
        PairingInlineBanner(
          text: view.quickActionsPrompt,
          backgroundColor: AppColors.white,
          borderColor: AppColors.cardBorder,
          foregroundColor: AppColors.ink,
        ),
        const SizedBox(height: Dimensions.md),
        Row(
          children: <Widget>[
            _HomeActionTile(
              icon: Icons.restaurant,
              title: Strings.homeFindDinner,
              subtitle: Strings.homeFindDinnerSubtitle,
              isPrimary: true,
              onTap: onTapFindDinner,
            ),
            const SizedBox(width: Dimensions.sm),
            _HomeActionTile(
              icon: Icons.groups,
              title: Strings.homeMyCircles,
              subtitle: Strings.homeActiveGroupsLabel(view.activeCircleCount),
              onTap: onTapMyCircles,
            ),
          ],
        ),
        const SizedBox(height: Dimensions.sm),
        Row(
          children: <Widget>[
            _HomeActionTile(
              icon: Icons.auto_awesome,
              title: Strings.homeStartCircle,
              subtitle: Strings.homeStartCircleSubtitle,
              onTap: onTapStartCircle,
            ),
            const SizedBox(width: Dimensions.sm),
            _HomeActionTile(
              icon: Icons.person,
              title: Strings.homeMyProfile,
              subtitle: Strings.homeMyProfileSubtitle,
              onTap: onTapMyProfile,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: Dimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: Dimensions.sm),
          child,
        ],
      ),
    );
  }
}

class _EmptySectionState extends StatelessWidget {
  const _EmptySectionState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
    );
  }
}

class _UpcomingDinnerRow extends StatelessWidget {
  const _UpcomingDinnerRow({required this.dinner});

  final HomeUpcomingDinner dinner;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Dimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                dinner.title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                '${dinner.circleName} · ${dinner.dateLabel} · ${dinner.timeLabel}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                '${dinner.venue} · ${dinner.city}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleSummaryRow extends StatelessWidget {
  const _CircleSummaryRow({required this.circle});

  final HomeCircleSummary circle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                circle.name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                '${circle.city} · ${circle.memberCount} members · ${circle.pairingFrequency}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: Dimensions.xs),
              Text(
                circle.nextPairingLabel,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimensions.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.sm, vertical: Dimensions.xs),
          decoration: BoxDecoration(
            color: AppColors.goldLight,
            borderRadius: BorderRadius.circular(Dimensions.radiusFull),
          ),
          child: Text(
            circle.inviteCode,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ConfirmedDinnerCard extends StatelessWidget {
  const _ConfirmedDinnerCard({
    required this.dinner,
    required this.onDetailsTap,
  });

  final HomeConfirmedDinner dinner;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: Dimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(dinner.badge, style: AppTextStyles.homeBadge),
                const SizedBox(height: Dimensions.xs),
                RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: dinner.dateLabel, style: AppTextStyles.homeConfirmedDate),
                      TextSpan(text: '  ${dinner.timeLabel}', style: AppTextStyles.homeConfirmedTime),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.xs),
                Text(
                  '${dinner.venue} · ${dinner.city}',
                  style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.sm),
          SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: onDetailsTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.inkFaint),
                foregroundColor: AppColors.ink,
                textStyle: AppTextStyles.buttonSecondary.copyWith(fontSize: 20),
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                ),
              ),
              child: const Text(Strings.homeDetailsCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenSeatCard extends StatelessWidget {
  const _OpenSeatCard({required this.seat, required this.onRequestSeat});

  final HomeOpenSeat seat;
  final VoidCallback onRequestSeat;

  @override
  Widget build(BuildContext context) {
    final LinearGradient gradient = seat.isHot
        ? const LinearGradient(
            colors: <Color>[AppColors.homeHotGradientStart, AppColors.homeHotGradientEnd],
          )
        : const LinearGradient(
            colors: <Color>[AppColors.homeCoolGradientStart, AppColors.homeCoolGradientEnd],
          );

    return Container(
      width: Dimensions.homeSeatCardWidth,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: Dimensions.homeSeatHeaderHeight,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusMd),
                topRight: Radius.circular(Dimensions.radiusMd),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.sm, vertical: Dimensions.sm),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.sm, vertical: Dimensions.xs),
                decoration: BoxDecoration(
                  color: AppColors.homeSeatPill,
                  borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                ),
                child: Text(
                  Strings.homeSeatsLeftLabel(seat.seatsLeft),
                  style: AppTextStyles.homeSeatPill,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.sm,
                Dimensions.sm,
                Dimensions.sm,
                Dimensions.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    seat.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeSeatTitle,
                  ),
                  const SizedBox(height: Dimensions.xs),
                  Text(
                    seat.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.dark,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                        ),
                        textStyle: AppTextStyles.buttonPrimary.copyWith(fontSize: 20),
                      ),
                      onPressed: onRequestSeat,
                      child: const Text(Strings.homeRequestSeatCta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionTile extends StatelessWidget {
  const _HomeActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isPrimary ? AppColors.dark : AppColors.white;
    final Color foregroundColor = isPrimary ? AppColors.white : AppColors.ink;

    return Expanded(
      child: SizedBox(
        height: Dimensions.actionTileHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusMd),
            border: Border.all(color: isPrimary ? AppColors.dark : AppColors.cardBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusMd),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, size: 18, color: foregroundColor),
                    const SizedBox(height: Dimensions.sm),
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm.copyWith(
                        color: isPrimary ? AppColors.creamDark : AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
