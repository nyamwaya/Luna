import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';

/// Displays a user-authored bubble in the conversation feed.
class UserBubble extends StatelessWidget {
  /// Creates a user bubble.
  const UserBubble({required this.text, super.key});

  /// The message body.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: Dimensions.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        child: Text(text, style: AppTextStyles.buttonPrimary),
      ),
    );
  }
}
