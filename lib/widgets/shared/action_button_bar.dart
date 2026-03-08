import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';

/// A reusable action row for conversation cards.
class ActionButtonBar extends StatelessWidget {
  /// Creates an action button bar.
  const ActionButtonBar({required this.children, super.key});

  /// The buttons displayed in the bar.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Dimensions.sm,
      runSpacing: Dimensions.sm,
      children: children,
    );
  }
}

/// Primary action button used inside conversation cards.
class PrimaryConversationButton extends StatelessWidget {
  /// Creates a primary conversation button.
  const PrimaryConversationButton({
    required this.label,
    this.onPressed,
    super.key,
  });

  /// The button label.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.md,
          vertical: Dimensions.sm,
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: AppTextStyles.buttonPrimary),
    );
  }
}

/// Secondary action button used inside conversation cards.
class SecondaryConversationButton extends StatelessWidget {
  /// Creates a secondary conversation button.
  const SecondaryConversationButton({
    required this.label,
    this.onPressed,
    super.key,
  });

  /// The button label.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.creamDark),
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.md,
          vertical: Dimensions.sm,
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: AppTextStyles.buttonSecondary),
    );
  }
}
