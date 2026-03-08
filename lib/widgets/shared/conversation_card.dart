import 'package:flutter/material.dart';

import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';

/// Shared card shell for contextual conversation widgets.
class ConversationCard extends StatelessWidget {
  /// Creates a conversation card.
  const ConversationCard({
    required this.title,
    this.subtitle,
    this.child,
    this.footer,
    super.key,
  });

  /// The primary heading text.
  final String title;

  /// The supporting description text.
  final String? subtitle;

  /// The primary content body.
  final Widget? child;

  /// Optional footer content rendered after the body.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: Dimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.h3),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: Dimensions.sm),
            Text(subtitle!, style: AppTextStyles.bodySm),
          ],
          if (child != null) ...<Widget>[
            const SizedBox(height: Dimensions.md),
            child!,
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: Dimensions.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
