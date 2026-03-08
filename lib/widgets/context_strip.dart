import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';

/// Displays the current shell context beneath the app bar.
class ContextStrip extends StatelessWidget {
  /// Creates a context strip.
  const ContextStrip({required this.label, super.key});

  /// The active shell context label.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.md,
        vertical: Dimensions.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.creamDark)),
      ),
      child: Text(label, style: AppTextStyles.bodySm),
    );
  }
}
