import 'dinner_event.dart';
import 'dinner_invite.dart';
import 'dinner_match.dart';
import 'match_detail.dart';

/// Represents the check-in state returned for a guest event view.
class DinnerEventCheckInState {
  /// Creates a check-in state.
  const DinnerEventCheckInState({
    this.eligible = false,
    this.myCheckedIn = false,
    this.partnerCheckedIn = false,
    this.windowOpensAt,
    this.windowClosesAt,
  });

  /// Creates a check-in state from serialized JSON.
  factory DinnerEventCheckInState.fromJson(Map<String, dynamic> json) {
    return DinnerEventCheckInState(
      eligible: json['eligible'] as bool? ?? false,
      myCheckedIn: json['my_checked_in'] as bool? ?? false,
      partnerCheckedIn: json['partner_checked_in'] as bool? ?? false,
      windowOpensAt: _parseDateTime(json['window_opens_at']),
      windowClosesAt: _parseDateTime(json['window_closes_at']),
    );
  }

  /// Whether check-in is currently available.
  final bool eligible;

  /// Whether the current user has checked in.
  final bool myCheckedIn;

  /// Whether the partner has checked in.
  final bool partnerCheckedIn;

  /// When the check-in window opens.
  final DateTime? windowOpensAt;

  /// When the check-in window closes.
  final DateTime? windowClosesAt;

  /// Converts the check-in state to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eligible': eligible,
      'my_checked_in': myCheckedIn,
      'partner_checked_in': partnerCheckedIn,
      'window_opens_at': windowOpensAt?.toIso8601String(),
      'window_closes_at': windowClosesAt?.toIso8601String(),
    };
  }

  /// Creates a modified copy of the check-in state.
  DinnerEventCheckInState copyWith({
    bool? eligible,
    bool? myCheckedIn,
    bool? partnerCheckedIn,
    DateTime? windowOpensAt,
    DateTime? windowClosesAt,
  }) {
    return DinnerEventCheckInState(
      eligible: eligible ?? this.eligible,
      myCheckedIn: myCheckedIn ?? this.myCheckedIn,
      partnerCheckedIn: partnerCheckedIn ?? this.partnerCheckedIn,
      windowOpensAt: windowOpensAt ?? this.windowOpensAt,
      windowClosesAt: windowClosesAt ?? this.windowClosesAt,
    );
  }
}

/// Represents the guest-facing dinner event payload used in shell widgets.
class GuestDinnerEventView {
  /// Creates a guest dinner event view.
  const GuestDinnerEventView({
    required this.event,
    required this.invite,
    this.match,
    this.partner,
    this.myConfirmed = false,
    this.myDeclinedAt,
    this.partnerConfirmed = false,
    this.checkIn = const DinnerEventCheckInState(),
    this.feedbackSubmitted = false,
  });

  /// Creates a guest dinner event view from serialized JSON.
  factory GuestDinnerEventView.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> eventJson = Map<String, dynamic>.from(
      (json['event'] as Map?) ?? const <String, dynamic>{},
    );
    final Map<String, dynamic> inviteJson = Map<String, dynamic>.from(
      (json['invite'] as Map?) ?? const <String, dynamic>{},
    );
    final Map<String, dynamic>? matchJson = (json['match'] as Map?) != null
        ? Map<String, dynamic>.from(json['match'] as Map<dynamic, dynamic>)
        : null;
    final Map<String, dynamic>? partnerJson = matchJson == null || matchJson['partner'] == null
        ? null
        : Map<String, dynamic>.from(matchJson['partner'] as Map<dynamic, dynamic>);
    final Map<String, dynamic> checkInJson = Map<String, dynamic>.from(
      (json['checkin'] as Map?) ?? const <String, dynamic>{},
    );

    return GuestDinnerEventView(
      event: DinnerEvent.fromJson(eventJson),
      invite: DinnerInvite.fromJson({...inviteJson, 'dinner_event_id': eventJson['id']}),
      match: matchJson == null ? null : DinnerMatch.fromJson(matchJson),
      partner: partnerJson == null ? null : MatchPartnerDetail.fromJson(partnerJson),
      myConfirmed: matchJson?['my_confirmed'] as bool? ?? false,
      myDeclinedAt: _parseDateTime(matchJson?['my_declined_at']),
      partnerConfirmed: matchJson?['partner_confirmed'] as bool? ?? false,
      checkIn: DinnerEventCheckInState.fromJson(checkInJson),
      feedbackSubmitted: json['feedback_submitted'] as bool? ?? false,
    );
  }

  /// The event summary.
  final DinnerEvent event;

  /// The current invite state.
  final DinnerInvite invite;

  /// The current match when available.
  final DinnerMatch? match;

  /// The matched partner when available.
  final MatchPartnerDetail? partner;

  /// Whether the current user has confirmed.
  final bool myConfirmed;

  /// When the current user declined.
  final DateTime? myDeclinedAt;

  /// Whether the partner has confirmed.
  final bool partnerConfirmed;

  /// The check-in state for the event.
  final DinnerEventCheckInState checkIn;

  /// Whether feedback has already been submitted.
  final bool feedbackSubmitted;

  /// Converts the guest event view to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event': event.toJson(),
      'invite': invite.toJson(),
      'match': match?.toJson(),
      'partner': partner?.toJson(),
      'my_confirmed': myConfirmed,
      'my_declined_at': myDeclinedAt?.toIso8601String(),
      'partner_confirmed': partnerConfirmed,
      'checkin': checkIn.toJson(),
      'feedback_submitted': feedbackSubmitted,
    };
  }

  /// Creates a modified copy of the guest event view.
  GuestDinnerEventView copyWith({
    DinnerEvent? event,
    DinnerInvite? invite,
    DinnerMatch? match,
    MatchPartnerDetail? partner,
    bool? myConfirmed,
    DateTime? myDeclinedAt,
    bool? partnerConfirmed,
    DinnerEventCheckInState? checkIn,
    bool? feedbackSubmitted,
  }) {
    return GuestDinnerEventView(
      event: event ?? this.event,
      invite: invite ?? this.invite,
      match: match ?? this.match,
      partner: partner ?? this.partner,
      myConfirmed: myConfirmed ?? this.myConfirmed,
      myDeclinedAt: myDeclinedAt ?? this.myDeclinedAt,
      partnerConfirmed: partnerConfirmed ?? this.partnerConfirmed,
      checkIn: checkIn ?? this.checkIn,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
