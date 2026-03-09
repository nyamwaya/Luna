import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';

/// Visual variants for pairing flow pill buttons.
enum PairingButtonTone {
  /// Dark filled button.
  dark,

  /// Gold filled button.
  gold,

  /// Dark outline button.
  outlineDark,

  /// Light outline button.
  outlineLight,

  /// Soft muted tile button.
  muted,
}

/// A rounded pill button used throughout the pairing flow UI.
class PairingPillButton extends StatelessWidget {
  /// Creates a pairing pill button.
  const PairingPillButton({
    required this.label,
    required this.tone,
    this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.expanded = true,
    super.key,
  });

  /// The button label.
  final String label;

  /// The visual tone for the button.
  final PairingButtonTone tone;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? leadingIcon;

  /// Optional trailing icon.
  final IconData? trailingIcon;

  /// Whether the button should fill available width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color border, Color foreground}) palette = switch (tone) {
      PairingButtonTone.dark => (
        background: AppColors.dark,
        border: AppColors.dark,
        foreground: AppColors.white,
      ),
      PairingButtonTone.gold => (
        background: AppColors.gold,
        border: AppColors.gold,
        foreground: AppColors.white,
      ),
      PairingButtonTone.outlineDark => (
        background: Colors.transparent,
        border: AppColors.darkBorder,
        foreground: AppColors.errorSoft,
      ),
      PairingButtonTone.outlineLight => (
        background: Colors.transparent,
        border: AppColors.cardBorder,
        foreground: AppColors.ink,
      ),
      PairingButtonTone.muted => (
        background: AppColors.mutedSurface,
        border: AppColors.mutedSurface,
        foreground: AppColors.inkSoft,
      ),
    };

    final Widget buttonChild = SizedBox(
      height: Dimensions.pillButtonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(Dimensions.radiusFull),
          border: Border.all(color: palette.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            onTap: onPressed,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (leadingIcon != null) ...<Widget>[
                      Icon(leadingIcon, size: 18, color: palette.foreground),
                      const SizedBox(width: Dimensions.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.buttonPrimary.copyWith(
                          color: palette.foreground,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...<Widget>[
                      const SizedBox(width: Dimensions.sm),
                      Icon(trailingIcon, size: 18, color: palette.foreground),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: buttonChild);
    }

    return IntrinsicWidth(child: buttonChild);
  }
}

/// A circular avatar that renders initials for preview states.
class PairingInitialAvatar extends StatelessWidget {
  /// Creates a preview avatar.
  const PairingInitialAvatar({
    required this.label,
    this.size = Dimensions.avatarLg,
    this.backgroundColor = AppColors.sage,
    this.foregroundColor = AppColors.white,
    super.key,
  });

  /// The initials or short label to display.
  final String label;

  /// The avatar diameter.
  final double size;

  /// The avatar background color.
  final Color backgroundColor;

  /// The text color.
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.h3.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A pill chip used for interests and tags in the pairing flow.
class PairingTagChip extends StatelessWidget {
  /// Creates a pairing tag chip.
  const PairingTagChip({
    required this.label,
    this.isSelected = true,
    this.leading,
    super.key,
  });

  /// The chip label.
  final String label;

  /// Whether the chip is emphasized.
  final bool isSelected;

  /// Optional leading emoji or icon text.
  final String? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.darkSoft : AppColors.card,
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
      ),
      child: Text(
        [if (leading != null) leading, label].join(' '),
        style: AppTextStyles.bodySm.copyWith(
          color: isSelected ? AppColors.white : AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A compact banner used for warnings and inline state notes.
class PairingInlineBanner extends StatelessWidget {
  /// Creates an inline banner.
  const PairingInlineBanner({
    required this.text,
    this.icon,
    this.backgroundColor = AppColors.card,
    this.borderColor = AppColors.cardBorder,
    this.foregroundColor = AppColors.ink,
    super.key,
  });

  /// The banner text.
  final String text;

  /// Optional leading icon.
  final IconData? icon;

  /// The banner background color.
  final Color backgroundColor;

  /// The banner border color.
  final Color borderColor;

  /// The text and icon color.
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: Dimensions.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: Dimensions.sm),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin progress indicator used inside pairing event cards.
class PairingProgressBar extends StatelessWidget {
  /// Creates a pairing progress bar.
  const PairingProgressBar({
    required this.progress,
    super.key,
  });

  /// The normalized completion value.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusFull),
      child: LinearProgressIndicator(
        minHeight: Dimensions.progressBarHeight,
        value: progress.clamp(0, 1),
        backgroundColor: AppColors.creamDark,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
      ),
    );
  }
}

/// A square action tile used in the confirmed dinner state.
class PairingActionTile extends StatelessWidget {
  /// Creates a pairing action tile.
  const PairingActionTile({
    required this.label,
    required this.icon,
    this.subtitle,
    this.foregroundColor = AppColors.ink,
    this.backgroundColor = AppColors.card,
    this.onTap,
    super.key,
  });

  /// The tile label.
  final String label;

  /// The tile icon.
  final IconData icon;

  /// Optional supporting text.
  final String? subtitle;

  /// The foreground color.
  final Color foregroundColor;

  /// The background color.
  final Color backgroundColor;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: Dimensions.actionTileHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusMd),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Dimensions.radiusMd),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(icon, color: foregroundColor, size: 22),
                    const SizedBox(height: Dimensions.sm),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: Dimensions.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.inkFaint),
                      ),
                    ],
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

/// A flexible rounded panel used throughout the pairing flow.
class PairingPanel extends StatelessWidget {
  /// Creates a pairing panel.
  const PairingPanel({
    required this.child,
    this.padding = const EdgeInsets.all(Dimensions.lg),
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.gradient,
    this.radius = 28,
    super.key,
  });

  /// The panel child.
  final Widget child;

  /// The panel padding.
  final EdgeInsetsGeometry padding;

  /// The panel fill color.
  final Color backgroundColor;

  /// Optional border color.
  final Color? borderColor;

  /// Optional background gradient.
  final Gradient? gradient;

  /// The corner radius.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}

/// A reusable dark match card for reveal and waiting states.
class PairingMatchCard extends StatelessWidget {
  /// Creates a pairing match card.
  const PairingMatchCard({
    required this.eyebrow,
    required this.name,
    required this.subtitle,
    required this.locationTitle,
    required this.locationSubtitle,
    required this.interests,
    this.avatarLabel = 'P',
    this.footer,
    this.topNotice,
    super.key,
  });

  /// The eyebrow label.
  final String eyebrow;

  /// The partner name.
  final String name;

  /// The partner subtitle.
  final String subtitle;

  /// The location title.
  final String locationTitle;

  /// The location subtitle.
  final String locationSubtitle;

  /// The interest labels.
  final List<String> interests;

  /// The avatar label.
  final String avatarLabel;

  /// Optional footer widget.
  final Widget? footer;

  /// Optional notice shown above the card.
  final Widget? topNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (topNotice != null) ...<Widget>[
          topNotice!,
          const SizedBox(height: Dimensions.md),
        ],
        PairingPanel(
          backgroundColor: AppColors.dark,
          radius: 30,
          padding: const EdgeInsets.all(Dimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(eyebrow, style: AppTextStyles.eyebrow),
              const SizedBox(height: Dimensions.md),
              Row(
                children: <Widget>[
                  PairingInitialAvatar(
                    label: avatarLabel,
                    size: Dimensions.avatarXl,
                    backgroundColor: AppColors.sage,
                  ),
                  const SizedBox(width: Dimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(name, style: AppTextStyles.panelTitleOnDark.copyWith(fontSize: 18)),
                        const SizedBox(height: Dimensions.xs),
                        Text(
                          subtitle,
                          style: AppTextStyles.body.copyWith(color: AppColors.creamDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.md),
              Wrap(
                spacing: Dimensions.sm,
                runSpacing: Dimensions.sm,
                children: interests
                    .map((String interest) => PairingTagChip(label: interest, isSelected: true))
                    .toList(growable: false),
              ),
              const SizedBox(height: Dimensions.md),
              PairingPanel(
                backgroundColor: AppColors.darkSoft,
                radius: Dimensions.radiusMd,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: Dimensions.md),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.location_pin, color: AppColors.errorSoft, size: 18),
                    const SizedBox(width: Dimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            locationTitle,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            locationSubtitle,
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.creamDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (footer != null) ...<Widget>[
                const SizedBox(height: Dimensions.lg),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The bottom conversation composer shown across pairing states.
class PairingComposer extends StatelessWidget {
  /// Creates a pairing composer.
  const PairingComposer({
    required this.placeholder,
    required this.onSend,
    this.controller,
    super.key,
  });

  /// The input placeholder.
  final String placeholder;

  /// The text controller.
  final TextEditingController? controller;

  /// Called when the user taps send.
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Dimensions.composerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                border: Border.all(color: AppColors.cardBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.lg),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: placeholder,
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.inkFaint),
                  contentPadding: const EdgeInsets.symmetric(vertical: Dimensions.md),
                ),
                style: AppTextStyles.body,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.sm),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: Dimensions.composerHeight,
              height: Dimensions.composerHeight,
              decoration: BoxDecoration(
                color: AppColors.dark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.dark),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_upward_rounded, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// The top inline notification row used beneath the app bar.
class PairingNotificationBar extends StatelessWidget {
  /// Creates a notification bar.
  const PairingNotificationBar({
    required this.label,
    required this.actionLabel,
    this.onTap,
    super.key,
  });

  /// The primary notification label.
  final String label;

  /// The trailing action label.
  final String actionLabel;

  /// Called when the bar is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: Dimensions.notificationHeight,
        child: Row(
          children: <Widget>[
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Just now · ',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.inkFaint),
                    ),
                    TextSpan(
                      text: label,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '$actionLabel ›',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
