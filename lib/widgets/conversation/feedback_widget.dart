import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../luma_message.dart';
import '../shared/pairing_ui_kit.dart';

/// Displays the feedback prompt within the conversation shell.
class FeedbackWidget extends StatelessWidget {
  /// Creates a feedback widget.
  const FeedbackWidget({
    required this.matchDetail,
    this.onSubmit,
    super.key,
  });

  /// The match detail payload to display.
  final MatchDetail matchDetail;

  /// Called when the user taps submit feedback.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final List<String> positiveTags = <String>[
      Strings.tagGreatConversation,
      Strings.tagPerfectVenue,
      Strings.tagWouldMeetAgain,
    ];
    final List<String> neutralTags = <String>[
      Strings.tagFeltAwkward,
      Strings.tagTooLoud,
      Strings.tagTooShort,
      Strings.tagGreatFood,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PairingPanel(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  5,
                  (int index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.xs),
                    child: Icon(
                      index < 4 ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 42,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.sm),
              Text(Strings.tapToRate, style: AppTextStyles.body.copyWith(color: AppColors.inkFaint)),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        Wrap(
          spacing: Dimensions.sm,
          runSpacing: Dimensions.sm,
          children: <Widget>[
            ...positiveTags.map((String tag) => PairingTagChip(label: tag, isSelected: true)),
            ...neutralTags.map((String tag) => PairingTagChip(label: tag, isSelected: false)),
          ],
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPanel(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.lg, vertical: Dimensions.md),
          child: Text(
            Strings.addNotePlaceholder,
            style: AppTextStyles.body.copyWith(color: AppColors.inkFaint),
          ),
        ),
        const SizedBox(height: Dimensions.lg),
        const LumaMessage(text: Strings.feedbackPhotoPrompt),
        const SizedBox(height: Dimensions.lg),
        Row(
          children: <Widget>[
            _PhotoTile(label: '🍽️'),
            const SizedBox(width: Dimensions.md),
            _PhotoTile(label: '🥂'),
            const SizedBox(width: Dimensions.md),
            const _PhotoTile(label: '+', dashed: true),
          ],
        ),
        const SizedBox(height: Dimensions.lg),
        PairingPillButton(
          label: '${Strings.feedbackSubmitCta} →',
          tone: PairingButtonTone.gold,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, this.dashed = false});

  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(Dimensions.radiusMd),
          border: Border.all(
            color: dashed ? AppColors.cardBorder : Colors.transparent,
            style: dashed ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.panelTitle.copyWith(color: AppColors.inkFaint),
        ),
      ),
    );
  }
}
