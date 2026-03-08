import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation_message.dart';
import '../../strings.dart';
import '../../widgets/context_strip.dart';
import '../../widgets/luma_message.dart';
import '../../widgets/quick_reply_chips.dart';
import '../../widgets/user_bubble.dart';
import 'conversation_shell_preview_data.dart';
import 'conversation_shell_state.dart';
import 'conversation_widget_resolver.dart';

class ConversationShell extends ConsumerWidget {
  const ConversationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ShellState state = ref.watch(conversationShellControllerProvider);
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);

    void showPreview(ShellWidget widget) {
      controller.showWidgetConfig(
        ShellWidgetConfig(widget, ConversationShellPreviewData.dataFor(widget)),
      );
      controller.addLumaMessage('Previewing ${_previewLabel(widget)}.');
    }

    void transitionTo(ShellWidget widget, String userMessage, String lumaMessage) {
      controller.addUserMessage(userMessage);
      controller.addLumaMessage(lumaMessage);
      controller.showWidgetConfig(
        ShellWidgetConfig(widget, ConversationShellPreviewData.dataFor(widget)),
      );
    }

    final Widget? resolvedWidget = ConversationWidgetResolver.resolve(
      state: state,
      onAcceptInvite: () => transitionTo(
        ShellWidget.waitingForPairs,
        Strings.acceptInviteCta,
        Strings.waitingForPairsSubtitle,
      ),
      onDeclineInvite: () {
        controller.addUserMessage(Strings.declineInviteCta);
        controller.addLumaMessage('Okay, I will skip this dinner invite.');
        controller.clearActiveWidget();
      },
      onConfirmMatch: () => transitionTo(
        ShellWidget.waitingForPartner,
        Strings.confirmCta,
        Strings.waitingForPartner,
      ),
      onDeclineMatch: () => transitionTo(
        ShellWidget.partnerDeclined,
        Strings.declineCta,
        Strings.partnerDeclinedSubtitle,
      ),
      onCancelSpot: () => transitionTo(
        ShellWidget.partnerDeclined,
        Strings.cancelSpotCta,
        Strings.partnerDeclinedSubtitle,
      ),
      onKeepMeIn: () => transitionTo(
        ShellWidget.waitingForPairs,
        Strings.keepMeInCta,
        Strings.requeuedMessage,
      ),
      onSkipRound: () {
        controller.addUserMessage(Strings.skipRoundCta);
        controller.addLumaMessage('Understood. I will skip this round for you.');
        controller.clearActiveWidget();
      },
      onAddToCalendar: () {
        controller.addUserMessage(Strings.addToCalendarCta);
        controller.addLumaMessage('Calendar integration will land in the next slice.');
      },
      onOpenCheckIn: () => transitionTo(
        ShellWidget.checkIn,
        Strings.checkInCta,
        Strings.checkInSubtitle,
      ),
      onReportAttendance: (bool attended) => transitionTo(
        ShellWidget.feedback,
        attended ? Strings.attendedYes : Strings.attendedNo,
        Strings.feedbackPrompt,
      ),
      onSubmitFeedback: () {
        controller.addUserMessage(Strings.feedbackSubmitCta);
        controller.addLumaMessage('Feedback capture is scaffolded and ready for the next backend slice.');
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.appTitle),
      ),
      body: Column(
        children: <Widget>[
          const ContextStrip(label: Strings.shellContextLabel),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(Strings.shellPreviewPrompt),
                const SizedBox(height: 8),
                QuickReplyChips(
                  options: shellPreviewOptions.map((ShellPreviewOption option) => option.label).toList(),
                  onSelected: (String label) {
                    final ShellPreviewOption option = shellPreviewOptions.firstWhere(
                      (ShellPreviewOption item) => item.label == label,
                    );
                    showPreview(option.widget);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: <Widget>[
                ...state.messages.map(_buildMessage),
                if (resolvedWidget != null) ...<Widget>[
                  const SizedBox(height: 12),
                  resolvedWidget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ConversationMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: switch (message.author) {
        ConversationAuthor.luma => LumaMessage(text: message.text),
        ConversationAuthor.user => UserBubble(text: message.text),
      },
    );
  }

  String _previewLabel(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.shellContextLabel,
      ShellWidget.dinnerInvite => Strings.previewInvite,
      ShellWidget.waitingForPairs => Strings.previewWaiting,
      ShellWidget.pairReveal => Strings.previewReveal,
      ShellWidget.waitingForPartner => Strings.previewPartner,
      ShellWidget.partnerDeclined => Strings.previewDeclined,
      ShellWidget.confirmedDinner => Strings.previewConfirmed,
      ShellWidget.checkIn => Strings.previewCheckIn,
      ShellWidget.attendanceReport => Strings.previewAttendance,
      ShellWidget.feedback => Strings.previewFeedback,
    };
  }
}
