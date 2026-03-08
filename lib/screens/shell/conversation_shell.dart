import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/conversation_message.dart';
import '../../strings.dart';
import '../../styles/app_colors.dart';
import '../../styles/dimensions.dart';
import '../../styles/text_styles.dart';
import '../../widgets/luma_message.dart';
import '../../widgets/shared/pairing_ui_kit.dart';
import '../../widgets/user_bubble.dart';
import 'conversation_shell_preview_data.dart';
import 'conversation_shell_state.dart';
import 'conversation_widget_resolver.dart';

class ConversationShell extends ConsumerStatefulWidget {
  const ConversationShell({super.key});

  @override
  ConsumerState<ConversationShell> createState() => _ConversationShellState();
}

class _ConversationShellState extends ConsumerState<ConversationShell> {
  late final TextEditingController _composerController;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activatePreview(ShellWidget.dinnerInvite);
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShellState state = ref.watch(conversationShellControllerProvider);
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);
    final ShellWidget activeWidget =
        state.activeWidget == ShellWidget.none ? ShellWidget.dinnerInvite : state.activeWidget;

    final Widget? resolvedWidget = ConversationWidgetResolver.resolve(
      state: state.activeWidget == ShellWidget.none
          ? state.copyWith(
              activeWidget: activeWidget,
              widgetData: ConversationShellPreviewData.dataFor(activeWidget),
            )
          : state,
      onAcceptInvite: () => _activatePreview(ShellWidget.waitingForPairs),
      onDeclineInvite: () => controller.clearActiveWidget(),
      onConfirmMatch: () => _activatePreview(ShellWidget.waitingForPartner),
      onDeclineMatch: () => _activatePreview(ShellWidget.partnerDeclined),
      onCancelSpot: () => _activatePreview(ShellWidget.partnerDeclined),
      onKeepMeIn: () => _activatePreview(ShellWidget.waitingForPairs),
      onSkipRound: () => controller.clearActiveWidget(),
      onAddToCalendar: () {},
      onOpenCheckIn: () => _activatePreview(ShellWidget.checkIn),
      onReportAttendance: (bool attended) {
        if (attended) {
          _activatePreview(ShellWidget.feedback);
          return;
        }

        controller.clearActiveWidget();
      },
      onSubmitFeedback: () {},
    );

    return Scaffold(
      backgroundColor: AppColors.shell,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            // ── Top chrome ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.md,
                  Dimensions.md,
                  Dimensions.md,
                  Dimensions.sm,
                ),
                child: Row(
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                      label: const Text(Strings.backLabel),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        textStyle: AppTextStyles.shellAction,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _headerTitleFor(activeWidget),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.shellTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showStatePicker,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Chat content ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.md,
                Dimensions.sm,
                Dimensions.md,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  <Widget>[
                    PairingNotificationBar(
                      label: _notificationLabelFor(activeWidget),
                      actionLabel: Strings.expandLabel,
                      onTap: _showStatePicker,
                    ),
                    const SizedBox(height: Dimensions.lg),
                    ...state.messages.map(_buildMessage),
                    if (resolvedWidget != null) ...<Widget>[
                      const SizedBox(height: Dimensions.lg),
                      resolvedWidget,
                    ],
                    const SizedBox(height: Dimensions.lg),
                  ],
                ),
              ),
            ),
            // ── Composer pinned to bottom of scroll area ─────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PairingComposer(
                  controller: _composerController,
                  placeholder: _composerPlaceholderFor(activeWidget),
                  onSend: _handleSend,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _activatePreview(ShellWidget widget) {
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);

    controller.replaceMessages(<ConversationMessage>[
      ConversationMessage.luma(text: _primaryMessageFor(widget)),
    ]);
    controller.showWidgetConfig(
      ShellWidgetConfig(widget, ConversationShellPreviewData.dataFor(widget)),
    );
  }

  void _handleSend() {
    final String text = _composerController.text.trim();
    if (text.isEmpty) {
      return;
    }

    ref.read(conversationShellControllerProvider.notifier).addUserMessage(text);
    _composerController.clear();
  }

  Future<void> _showStatePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.md),
          children: shellPreviewOptions
              .map(
                (ShellPreviewOption option) => ListTile(
                  title: Text(option.label, style: AppTextStyles.body),
                  onTap: () {
                    Navigator.of(context).pop();
                    _activatePreview(option.widget);
                  },
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildMessage(ConversationMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.lg),
      child: switch (message.author) {
        ConversationAuthor.luma => LumaMessage(text: message.text),
        ConversationAuthor.user => UserBubble(text: message.text),
      },
    );
  }

  String _headerTitleFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.headerInvitePending,
      ShellWidget.dinnerInvite => Strings.headerInvitePending,
      ShellWidget.waitingForPairs => Strings.headerInviteAccepted,
      ShellWidget.pairReveal => Strings.headerMatchRevealed,
      ShellWidget.waitingForPartner => Strings.headerMatchPending,
      ShellWidget.partnerDeclined => Strings.headerMatchCancelled,
      ShellWidget.confirmedDinner => Strings.headerDinnerConfirmed,
      ShellWidget.checkIn => Strings.headerDinnerCheckIn,
      ShellWidget.attendanceReport => Strings.headerPostDinner,
      ShellWidget.feedback => Strings.headerFeedback,
    };
  }

  String _notificationLabelFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.notificationNew,
      ShellWidget.dinnerInvite => Strings.notificationNew,
      ShellWidget.waitingForPairs => Strings.notificationAcceptedInvite,
      ShellWidget.pairReveal => Strings.notificationPairReady,
      ShellWidget.waitingForPartner => Strings.notificationConfirmedMatch,
      ShellWidget.partnerDeclined => Strings.notificationMatchUpdate,
      ShellWidget.confirmedDinner => Strings.notificationPairReady,
      ShellWidget.checkIn => Strings.notificationTonightDinner,
      ShellWidget.attendanceReport => Strings.notificationPostDinner,
      ShellWidget.feedback => Strings.notificationPostDinner,
    };
  }

  String _composerPlaceholderFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.confirmedDinner => Strings.askAboutYourDinnerPlaceholder,
      ShellWidget.dinnerInvite => Strings.askAboutDinnerPlaceholder,
      _ => Strings.saySomethingPlaceholder,
    };
  }

  String _primaryMessageFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.shellIntroMessage,
      ShellWidget.dinnerInvite =>
        'You\'ve been invited to a dinner by Marcus. Want to join the pool?',
      ShellWidget.waitingForPairs =>
        'You\'re in the pool. Pairs drop in 4 days — I\'ll notify you the moment yours is ready.',
      ShellWidget.pairReveal =>
        'Your dinner partner is here. You and Priya share a lot in common — confirm to lock it in.',
      ShellWidget.waitingForPartner =>
        'You\'re confirmed. Waiting for Priya to confirm her side — I\'ll let you know as soon as she does.',
      ShellWidget.partnerDeclined =>
        'Priya can\'t make this one. You\'ve been re-added to the pool — I\'ll find you a new match if there\'s someone available.',
      ShellWidget.confirmedDinner =>
        'You\'re both in. Priya confirmed too — see you Thursday at Spoon & Stable.',
      ShellWidget.checkIn =>
        'You\'re near Spoon & Stable. Check in to let Priya know you\'re here.',
      ShellWidget.attendanceReport =>
        'Hope the evening was great. Did you make it to dinner?',
      ShellWidget.feedback =>
        'Glad you went. How was the dinner with Priya?',
    };
  }
}
