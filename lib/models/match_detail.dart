import 'dinner_event.dart';
import 'dinner_match.dart';
import 'match_guest.dart';
import 'user_profile.dart';

/// Represents a minimal circle summary used in shell widgets.
class CircleSummary {
  /// Creates a circle summary.
  const CircleSummary({required this.id, required this.name});

  /// Creates a circle summary from serialized JSON.
  factory CircleSummary.fromJson(Map<String, dynamic> json) {
    return CircleSummary(
      id: (json['id'] ?? json['circle_id'] ?? '') as String,
      name: (json['name'] ?? json['circle_name'] ?? '') as String,
    );
  }

  /// The unique identifier for the circle.
  final String id;

  /// The display name for the circle.
  final String name;

  /// Converts the circle summary to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  /// Creates a modified copy of the circle summary.
  CircleSummary copyWith({String? id, String? name}) {
    return CircleSummary(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}

/// Represents the partner-facing detail used by pairing widgets.
class MatchPartnerDetail {
  /// Creates a partner detail.
  const MatchPartnerDetail({
    required this.profile,
    this.sharedInterests = const <String>[],
    this.confirmed = false,
    this.declinedAt,
    this.checkedIn = false,
  });

  /// Creates a partner detail from serialized JSON.
  factory MatchPartnerDetail.fromJson(Map<String, dynamic> json) {
    return MatchPartnerDetail(
      profile: UserProfile.fromJson(json),
      sharedInterests: _parseStringList(json['shared_interests']),
      confirmed: json['confirmed'] as bool? ?? json['partner_confirmed'] as bool? ?? false,
      declinedAt: _parseDateTime(json['declined_at']),
      checkedIn: json['checked_in'] as bool? ?? false,
    );
  }

  /// The partner profile.
  final UserProfile profile;

  /// The interests shared between the two guests.
  final List<String> sharedInterests;

  /// Whether the partner has confirmed.
  final bool confirmed;

  /// When the partner declined the match.
  final DateTime? declinedAt;

  /// Whether the partner has checked in.
  final bool checkedIn;

  /// Converts the partner detail to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      ...profile.toJson(),
      'shared_interests': sharedInterests,
      'confirmed': confirmed,
      'declined_at': declinedAt?.toIso8601String(),
      'checked_in': checkedIn,
    };
  }

  /// Creates a modified copy of the partner detail.
  MatchPartnerDetail copyWith({
    UserProfile? profile,
    List<String>? sharedInterests,
    bool? confirmed,
    DateTime? declinedAt,
    bool? checkedIn,
  }) {
    return MatchPartnerDetail(
      profile: profile ?? this.profile,
      sharedInterests: sharedInterests ?? this.sharedInterests,
      confirmed: confirmed ?? this.confirmed,
      declinedAt: declinedAt ?? this.declinedAt,
      checkedIn: checkedIn ?? this.checkedIn,
    );
  }
}

/// Represents the full match payload used by shell widgets.
class MatchDetail {
  /// Creates a match detail.
  const MatchDetail({
    required this.match,
    required this.event,
    required this.me,
    this.circle,
    this.partner,
    this.feedbackSubmitted = false,
  });

  /// Creates a match detail from serialized JSON.
  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> matchJson = Map<String, dynamic>.from(
      (json['match'] as Map?) ?? const <String, dynamic>{},
    );
    final Map<String, dynamic> eventJson = Map<String, dynamic>.from(
      (json['event'] as Map?) ?? const <String, dynamic>{},
    );
    final Map<String, dynamic> meJson = Map<String, dynamic>.from(
      (json['me'] as Map?) ?? const <String, dynamic>{},
    );
    final Map<String, dynamic>? circleJson = (json['circle'] as Map?) != null
        ? Map<String, dynamic>.from(json['circle'] as Map<dynamic, dynamic>)
        : null;
    final Map<String, dynamic>? partnerJson = (json['partner'] as Map?) != null
        ? Map<String, dynamic>.from(json['partner'] as Map<dynamic, dynamic>)
        : null;

    return MatchDetail(
      match: DinnerMatch.fromJson(matchJson),
      event: DinnerEvent.fromJson(eventJson),
      me: MatchGuest.fromJson(meJson),
      circle: circleJson == null ? null : CircleSummary.fromJson(circleJson),
      partner: partnerJson == null ? null : MatchPartnerDetail.fromJson(partnerJson),
      feedbackSubmitted: json['feedback_submitted'] as bool? ?? false,
    );
  }

  /// The core match row.
  final DinnerMatch match;

  /// The associated dinner event.
  final DinnerEvent event;

  /// The current user's guest state.
  final MatchGuest me;

  /// The associated circle summary.
  final CircleSummary? circle;

  /// The partner information when available.
  final MatchPartnerDetail? partner;

  /// Whether feedback has already been submitted.
  final bool feedbackSubmitted;

  /// Whether the match should be treated as revealed in the UI.
  bool get revealed {
    final DateTime? revealAt = match.revealAt;
    if (revealAt == null) {
      return true;
    }

    return DateTime.now().isAfter(revealAt) ||
        match.status == MatchStatus.revealed ||
        match.status == MatchStatus.confirmed ||
        match.status == MatchStatus.completed ||
        match.status == MatchStatus.cancelled;
  }

  /// Converts the match detail to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'match': match.toJson(),
      'event': event.toJson(),
      'me': me.toJson(),
      'circle': circle?.toJson(),
      'partner': partner?.toJson(),
      'feedback_submitted': feedbackSubmitted,
    };
  }

  /// Creates a modified copy of the match detail.
  MatchDetail copyWith({
    DinnerMatch? match,
    DinnerEvent? event,
    MatchGuest? me,
    CircleSummary? circle,
    MatchPartnerDetail? partner,
    bool? feedbackSubmitted,
  }) {
    return MatchDetail(
      match: match ?? this.match,
      event: event ?? this.event,
      me: me ?? this.me,
      circle: circle ?? this.circle,
      partner: partner ?? this.partner,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
    );
  }
}

List<String> _parseStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList(growable: false);
  }

  return const <String>[];
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
