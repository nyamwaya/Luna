import 'package:flutter/material.dart';

import '../strings.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.auto_awesome, size: 12, color: AppColors.gold),
            const SizedBox(width: Dimensions.xs),
            Text(Strings.shellSectionLabel, style: AppTextStyles.eyebrow),
          ],
        ),
        const SizedBox(height: Dimensions.sm),
        Text(
          text,
          style: AppTextStyles.bodyLg.copyWith(
            height: 1.55,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
