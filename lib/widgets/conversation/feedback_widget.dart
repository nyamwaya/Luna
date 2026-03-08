import 'package:flutter/material.dart';

import '../../models/match_detail.dart';
import '../../strings.dart';
import '../shared/action_button_bar.dart';
import '../shared/conversation_card.dart';
import '../shared/labeled_value.dart';

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
    return ConversationCard(
      title: Strings.feedbackPrompt,
      subtitle: Strings.feedbackSubtitle,
      footer: ActionButtonBar(
        children: <Widget>[
          PrimaryConversationButton(label: Strings.feedbackSubmitCta, onPressed: onSubmit),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LabeledValue(
            label: Strings.eventLabel,
            value: matchDetail.event.title,
          ),
          LabeledValue(
            label: Strings.partnerLabel,
            value: matchDetail.partner?.profile.firstName ?? Strings.valuePending,
          ),
          LabeledValue(
            label: Strings.feedbackStatusLabel,
            value: matchDetail.feedbackSubmitted
                ? Strings.feedbackSubmittedStatus
                : Strings.feedbackPendingStatus,
          ),
        ],
      ),
    );
  }
}
