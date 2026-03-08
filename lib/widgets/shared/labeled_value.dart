import 'package:flutter/material.dart';

import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';

/// Displays a label/value pair inside a conversation card.
class LabeledValue extends StatelessWidget {
  /// Creates a labeled value row.
  const LabeledValue({
    required this.label,
    required this.value,
    super.key,
  });

  /// The row label.
  final String label;

  /// The row value.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(label, style: AppTextStyles.bodySm),
          ),
          const SizedBox(width: Dimensions.sm),
          Expanded(
            flex: 5,
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}
