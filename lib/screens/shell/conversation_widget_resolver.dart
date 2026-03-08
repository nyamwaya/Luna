import 'package:flutter/material.dart';

import '../../models/dinner_invite.dart';
import '../../models/guest_dinner_event_view.dart';
import '../../models/match_detail.dart';
import '../../strings.dart';
import '../../widgets/conversation/attendance_report_card.dart';
import '../../widgets/conversation/check_in_widget.dart';
import '../../widgets/conversation/confirmed_dinner_card.dart';
import '../../widgets/conversation/dinner_invite_card.dart';
import '../../widgets/conversation/feedback_widget.dart';
import '../../widgets/conversation/pair_reveal_card.dart';
import '../../widgets/conversation/partner_declined_card.dart';
import '../../widgets/conversation/waiting_for_pairs_card.dart';
import '../../widgets/conversation/waiting_for_partner_card.dart';
import 'conversation_shell_state.dart';

/// Resolves the current shell widget into a concrete conversation widget.
abstract final class ConversationWidgetResolver {
  /// Returns the widget for the active shell state.
  static Widget? resolve({
    required ShellState state,
    required VoidCallback onAcceptInvite,
    required VoidCallback onDeclineInvite,
    required VoidCallback onConfirmMatch,
    required VoidCallback onDeclineMatch,
    required VoidCallback onCancelSpot,
    required VoidCallback onKeepMeIn,
    required VoidCallback onSkipRound,
    required VoidCallback onAddToCalendar,
    required VoidCallback onOpenCheckIn,
    required ValueChanged<bool> onReportAttendance,
    required VoidCallback onSubmitFeedback,
  }) {
    switch (state.activeWidget) {
      case ShellWidget.none:
        return null;
      case ShellWidget.dinnerInvite:
        return DinnerInviteCard(
          invite: DinnerInvite.fromJson(state.widgetData),
          onAccept: onAcceptInvite,
          onDecline: onDeclineInvite,
        );
      case ShellWidget.waitingForPairs:
        return WaitingForPairsCard(
          view: GuestDinnerEventView.fromJson(state.widgetData),
        );
      case ShellWidget.pairReveal:
        return PairRevealCard(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onConfirm: onConfirmMatch,
          onDecline: onDeclineMatch,
        );
      case ShellWidget.waitingForPartner:
        return WaitingForPartnerCard(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onCancel: onCancelSpot,
        );
      case ShellWidget.partnerDeclined:
        return PartnerDeclinedCard(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onKeepMeIn: onKeepMeIn,
          onSkip: onSkipRound,
        );
      case ShellWidget.confirmedDinner:
        return ConfirmedDinnerCard(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onAddToCalendar: onAddToCalendar,
          onCheckIn: onOpenCheckIn,
          onCancel: onDeclineMatch,
        );
      case ShellWidget.checkIn:
        return CheckInWidget(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onCheckIn: onOpenCheckIn,
        );
      case ShellWidget.attendanceReport:
        return AttendanceReportCard(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onReport: onReportAttendance,
        );
      case ShellWidget.feedback:
        return FeedbackWidget(
          matchDetail: MatchDetail.fromJson(state.widgetData),
          onSubmit: onSubmitFeedback,
        );
    }
  }
}

/// A selectable shell preview state.
class ShellPreviewOption {
  /// Creates a shell preview option.
  const ShellPreviewOption({
    required this.label,
    required this.widget,
  });

  /// The chip label.
  final String label;

  /// The widget represented by the chip.
  final ShellWidget widget;
}

/// The supported shell preview states for the pairing foundation.
const List<ShellPreviewOption> shellPreviewOptions = <ShellPreviewOption>[
  ShellPreviewOption(label: Strings.previewInvite, widget: ShellWidget.dinnerInvite),
  ShellPreviewOption(label: Strings.previewWaiting, widget: ShellWidget.waitingForPairs),
  ShellPreviewOption(label: Strings.previewReveal, widget: ShellWidget.pairReveal),
  ShellPreviewOption(label: Strings.previewPartner, widget: ShellWidget.waitingForPartner),
  ShellPreviewOption(label: Strings.previewDeclined, widget: ShellWidget.partnerDeclined),
  ShellPreviewOption(label: Strings.previewConfirmed, widget: ShellWidget.confirmedDinner),
  ShellPreviewOption(label: Strings.previewCheckIn, widget: ShellWidget.checkIn),
  ShellPreviewOption(label: Strings.previewAttendance, widget: ShellWidget.attendanceReport),
  ShellPreviewOption(label: Strings.previewFeedback, widget: ShellWidget.feedback),
];
