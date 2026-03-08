import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_logger.dart';
import '../../models/conversation_message.dart';
import '../../models/home/home_dashboard_view.dart';
import '../../repositories/conversation_repository.dart';
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
  late final ConversationRepository _conversationRepository;
  dynamic _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();
    _conversationRepository = ConversationRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRealtimeConversation();
    });
  }

  List<ConversationMessage> _visibleMessagesForDisplay({
    required List<ConversationMessage> allMessages,
    required ShellWidget activeWidget,
  }) {
    if (activeWidget != ShellWidget.homeDashboard || allMessages.length <= 2) {
      return allMessages;
    }

    final int lastUserIndex = allMessages.lastIndexWhere(
      (ConversationMessage message) => message.author == ConversationAuthor.user,
    );
    if (lastUserIndex == -1) {
      return <ConversationMessage>[allMessages.last];
    }

    return allMessages.sublist(lastUserIndex);
  }

  Widget _buildHistorySummaryCard({
    required int collapsedMessageCount,
    required List<ConversationMessage> allMessages,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: Dimensions.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              Strings.homeHistorySummaryLabel(collapsedMessageCount),
              style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => _showHistoryDrawer(allMessages),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              textStyle: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
            ),
            child: const Text(Strings.expandLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showHistoryDrawer(List<ConversationMessage> allMessages) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.shell,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.md,
              Dimensions.md,
              Dimensions.md,
              Dimensions.md,
            ),
            child: Column(
              children: <Widget>[
                Text(
                  Strings.homeHistoryDrawerTitle,
                  style: AppTextStyles.h3.copyWith(fontSize: 26),
                ),
                const SizedBox(height: Dimensions.md),
                Expanded(
                  child: ListView(
                    children: allMessages.map(_buildMessage).toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShellState state = ref.watch(conversationShellControllerProvider);
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);
    final ShellWidget activeWidget =
        state.activeWidget == ShellWidget.none ? ShellWidget.homeDashboard : state.activeWidget;
    final List<ConversationMessage> visibleMessages = _visibleMessagesForDisplay(
      allMessages: state.messages,
      activeWidget: activeWidget,
    );
    final int collapsedMessageCount = state.messages.length - visibleMessages.length;
    final HomeDashboardView? homeView =
        activeWidget == ShellWidget.homeDashboard && state.widgetData.isNotEmpty
        ? HomeDashboardView.fromJson(state.widgetData)
        : null;

    final Widget? resolvedWidget = ConversationWidgetResolver.resolve(
      state: state.activeWidget == ShellWidget.none
          ? state.copyWith(activeWidget: activeWidget)
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
      onOpenHomeDinnerDetails: () {
        _sendMessageText('Show me my upcoming dinners.');
      },
      onRequestHomeSeat: (HomeOpenSeat seat) {
        controller.addLumaMessage(
          '${Strings.homeSeatRequested} ${seat.title}.',
        );
      },
      onTapHomeFindDinner: () {
        _sendMessageText('Show me open dinners nearby.');
      },
      onTapHomeMyCircles: () {
        _sendMessageText('Show me my circles.');
      },
      onTapHomeStartCircle: () {
        _sendMessageText('Help me create a new circle.');
      },
      onTapHomeMyProfile: () {
        controller.addLumaMessage(Strings.homeMyProfileTapped);
      },
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
                child: _buildTopChrome(activeWidget, homeView),
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
                    if (activeWidget != ShellWidget.homeDashboard) ...<Widget>[
                      PairingNotificationBar(
                        label: _notificationLabelFor(activeWidget),
                        actionLabel: Strings.expandLabel,
                        onTap: _showStatePicker,
                      ),
                      const SizedBox(height: Dimensions.lg),
                    ],
                    if (activeWidget == ShellWidget.homeDashboard && resolvedWidget != null) ...<Widget>[
                      resolvedWidget,
                      const SizedBox(height: Dimensions.lg),
                    ],
                    if (activeWidget == ShellWidget.homeDashboard && collapsedMessageCount > 0)
                      ...<Widget>[
                      _buildHistorySummaryCard(
                        collapsedMessageCount: collapsedMessageCount,
                        allMessages: state.messages,
                      ),
                      const SizedBox(height: Dimensions.lg),
                    ],
                    ...visibleMessages.map(_buildMessage),
                    if (activeWidget != ShellWidget.homeDashboard && resolvedWidget != null)
                      ...<Widget>[
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

  Widget _buildTopChrome(ShellWidget widget, HomeDashboardView? homeView) {
    if (widget == ShellWidget.homeDashboard) {
      final HomeDashboardView currentHomeView =
          homeView ??
          const HomeDashboardView(
            city: Strings.homeCity,
            userInitials: 'ME',
            quickActionsPrompt: '',
            openSeatsPrompt: '',
            openSeats: <HomeOpenSeat>[],
            activeCircleCount: 0,
          );

      return Row(
        children: <Widget>[
          CircleAvatar(
            radius: Dimensions.avatarMd / 2,
            backgroundColor: AppColors.goldLight,
            child: Text(
              currentHomeView.userInitials,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(currentHomeView.city, style: AppTextStyles.h3.copyWith(fontSize: 30)),
                const SizedBox(width: Dimensions.xs),
                const Icon(Icons.expand_more, color: AppColors.inkSoft),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showShellActions,
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
      );
    }

    return Row(
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
            _headerTitleFor(widget),
            textAlign: TextAlign.center,
            style: AppTextStyles.shellTitle,
          ),
        ),
        GestureDetector(
          onTap: _showShellActions,
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

  Future<void> _initializeRealtimeConversation() async {
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);

    await _messagesSubscription?.cancel();
    _messagesSubscription = null;

    controller.setActiveWidget(ShellWidget.homeDashboard, const <String, dynamic>{});
    controller.setLoading(true);

    try {
      await _conversationRepository.ensureDefaultConversation();
      final HomeDashboardView? homeDashboard = await _conversationRepository.loadHomeDashboard();
      if (homeDashboard != null) {
        controller.showWidgetConfig(
          ShellWidgetConfig(
            ShellWidget.homeDashboard,
            homeDashboard.toJson(),
          ),
        );
      }

      _messagesSubscription = await _conversationRepository.subscribeToMessages(
        onMessages: (List<ConversationMessage> messages) {
          if (!mounted) {
            return;
          }

          if (messages.isEmpty) {
            controller.replaceMessages(<ConversationMessage>[
              ConversationMessage.luma(text: Strings.shellIntroMessage),
            ]);
            return;
          }

          controller.replaceMessages(messages);
        },
        onError: (_) {
          if (!mounted) {
            return;
          }

          controller.addLumaMessage(Strings.realtimeConnectionIssueMessage);
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize realtime conversation',
        error: error,
        stackTrace: stackTrace,
      );
      controller.addLumaMessage(Strings.sendMessageFailedMessage);
    } finally {
      controller.setLoading(false);
    }
  }

  Future<void> _resetConversation() async {
    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);
    controller.setLoading(true);

    try {
      await _conversationRepository.resetConversation();
      await _initializeRealtimeConversation();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to reset conversation',
        error: error,
        stackTrace: stackTrace,
      );
      controller.addLumaMessage(Strings.conversationResetFailedMessage);
      controller.setLoading(false);
    }
  }

  Future<void> _showShellActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.md),
          shrinkWrap: true,
          children: <Widget>[
            ListTile(
              title: const Text(Strings.newConversationLabel, style: AppTextStyles.body),
              onTap: () {
                Navigator.of(context).pop();
                _resetConversation();
              },
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            ...shellPreviewOptions.map(
              (ShellPreviewOption option) => ListTile(
                title: Text(option.label, style: AppTextStyles.body),
                onTap: () {
                  Navigator.of(context).pop();
                  _activatePreview(option.widget);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSend() async {
    final String text = _composerController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _composerController.clear();

    await _sendMessageText(text);
  }

  Future<void> _sendMessageText(String text) async {
    final String normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    final ConversationShellController controller =
        ref.read(conversationShellControllerProvider.notifier);
    controller.setLoading(true);

    try {
      final List<ConversationMessage> latestMessages = await _conversationRepository
          .sendUserMessageAndGenerateReply(text: normalizedText);
      if (latestMessages.isNotEmpty) {
        controller.replaceMessages(latestMessages);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to send user message',
        error: error,
        stackTrace: stackTrace,
      );
      controller.addLumaMessage(Strings.sendMessageFailedMessage);
    } finally {
      controller.setLoading(false);
    }
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
        ConversationAuthor.luma => LumaMessage(text: message.text, metadata: message.metadata),
        ConversationAuthor.user => UserBubble(text: message.text),
      },
    );
  }

  String _headerTitleFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.headerInvitePending,
      ShellWidget.homeDashboard => Strings.headerHome,
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
      ShellWidget.homeDashboard => Strings.notificationNew,
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
      ShellWidget.homeDashboard => Strings.homeComposerPlaceholder,
      ShellWidget.confirmedDinner => Strings.askAboutYourDinnerPlaceholder,
      ShellWidget.dinnerInvite => Strings.askAboutDinnerPlaceholder,
      _ => Strings.saySomethingPlaceholder,
    };
  }

  String _primaryMessageFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => Strings.shellIntroMessage,
      ShellWidget.homeDashboard => Strings.homePrimaryMessage,
      ShellWidget.dinnerInvite => Strings.shellDinnerInviteMessage,
      ShellWidget.waitingForPairs => Strings.shellWaitingForPairsMessage,
      ShellWidget.pairReveal => Strings.shellPairRevealMessage,
      ShellWidget.waitingForPartner => Strings.shellWaitingForPartnerMessage,
      ShellWidget.partnerDeclined => Strings.shellPartnerDeclinedMessage,
      ShellWidget.confirmedDinner => Strings.shellConfirmedDinnerMessage,
      ShellWidget.checkIn => Strings.shellCheckInMessage,
      ShellWidget.attendanceReport => Strings.shellAttendanceReportMessage,
      ShellWidget.feedback => Strings.shellFeedbackMessage,
    };
  }
}
