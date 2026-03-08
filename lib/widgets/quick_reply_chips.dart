import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';

/// Renders a horizontal list of quick reply chips.
class QuickReplyChips extends StatelessWidget {
  /// Creates quick reply chips.
  const QuickReplyChips({
    required this.options,
    required this.onSelected,
    super.key,
  });

  /// The display labels for each chip.
  final List<String> options;

  /// Called when a chip is selected.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map(
              (String option) => Padding(
                padding: const EdgeInsets.only(right: Dimensions.sm),
                child: ActionChip(
                  backgroundColor: AppColors.cream,
                  side: const BorderSide(color: AppColors.creamDark),
                  label: Text(option, style: AppTextStyles.bodySm.copyWith(color: AppColors.ink)),
                  onPressed: () => onSelected(option),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
