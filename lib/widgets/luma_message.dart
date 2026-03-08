import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';

/// Displays a Luma-authored message bubble in the conversation feed.
class LumaMessage extends StatelessWidget {
  /// Creates a Luma message bubble.
  const LumaMessage({required this.text, super.key});

  /// The message body.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: Dimensions.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        child: Text(text, style: AppTextStyles.body),
      ),
    );
  }
}
