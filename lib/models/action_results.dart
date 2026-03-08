import 'dinner_invite.dart';
import 'dinner_match.dart';

/// Represents the result of responding to a dinner invite.
class InviteResponseResult {
  /// Creates an invite response result.
  const InviteResponseResult({
    required this.inviteId,
    required this.status,
    required this.dinnerEventId,
    this.error,
  });

  /// Creates an invite response result from serialized JSON.
  factory InviteResponseResult.fromJson(Map<String, dynamic> json) {
    return InviteResponseResult(
      inviteId: json['invite_id'] as String? ?? '',
      status: InviteStatus.fromString(json['status'] as String?),
      dinnerEventId: json['dinner_event_id'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  /// The invite identifier.
  final String inviteId;

  /// The new invite status.
  final InviteStatus status;

  /// The associated event identifier.
  final String dinnerEventId;

  /// The error returned by the RPC when available.
  final String? error;

  /// Converts the result to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'invite_id': inviteId,
      'status': status.value,
      'dinner_event_id': dinnerEventId,
      'error': error,
    };
  }
}

/// Represents the result of a match confirmation or decline action.
class MatchActionResult {
  /// Creates a match action result.
  const MatchActionResult({
    required this.matchId,
    this.matchStatus = MatchStatus.unknown,
    this.allConfirmed = false,
    this.cancellationPolicy,
    this.requeued = false,
    this.error,
  });

  /// Creates a match action result from serialized JSON.
  factory MatchActionResult.fromJson(Map<String, dynamic> json) {
    return MatchActionResult(
      matchId: json['match_id'] as String? ?? '',
      matchStatus: MatchStatus.fromString(json['match_status'] as String? ?? json['status'] as String?),
      allConfirmed: json['all_confirmed'] as bool? ?? false,
      cancellationPolicy: json['cancellation_policy'] as String?,
      requeued: json['requeued'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  /// The match identifier.
  final String matchId;

  /// The resulting match status.
  final MatchStatus matchStatus;

  /// Whether all guests are now confirmed.
  final bool allConfirmed;

  /// The cancellation policy when relevant.
  final String? cancellationPolicy;

  /// Whether the user was requeued.
  final bool requeued;

  /// The error returned by the RPC when available.
  final String? error;

  /// Converts the result to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'match_id': matchId,
      'match_status': matchStatus.value,
      'all_confirmed': allConfirmed,
      'cancellation_policy': cancellationPolicy,
      'requeued': requeued,
      'error': error,
    };
  }
}

/// Represents the result of a dinner check-in action.
class CheckInResult {
  /// Creates a check-in result.
  const CheckInResult({
    this.checkedIn = false,
    this.distanceMeters = 0,
    this.partnerCheckedIn = false,
    this.windowOpensAt,
    this.windowClosesAt,
    this.error,
  });

  /// Creates a check-in result from serialized JSON.
  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      checkedIn: json['checked_in'] as bool? ?? false,
      distanceMeters: (json['distance_meters'] as num?)?.toInt() ?? 0,
      partnerCheckedIn: json['partner_checked_in'] as bool? ?? false,
      windowOpensAt: _parseDateTime(json['window_opens_at']),
      windowClosesAt: _parseDateTime(json['window_closes_at']),
      error: json['error'] as String?,
    );
  }

  /// Whether the check-in was recorded.
  final bool checkedIn;

  /// The computed distance from the venue in meters.
  final int distanceMeters;

  /// Whether the partner has checked in.
  final bool partnerCheckedIn;

  /// When the check-in window opens.
  final DateTime? windowOpensAt;

  /// When the check-in window closes.
  final DateTime? windowClosesAt;

  /// The error returned by the RPC when available.
  final String? error;

  /// Converts the result to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'checked_in': checkedIn,
      'distance_meters': distanceMeters,
      'partner_checked_in': partnerCheckedIn,
      'window_opens_at': windowOpensAt?.toIso8601String(),
      'window_closes_at': windowClosesAt?.toIso8601String(),
      'error': error,
    };
  }
}

/// Represents the result of reporting attendance.
class AttendanceReportResult {
  /// Creates an attendance report result.
  const AttendanceReportResult({
    required this.matchId,
    required this.attended,
    this.reportedAt,
    this.deadline,
    this.error,
  });

  /// Creates an attendance report result from serialized JSON.
  factory AttendanceReportResult.fromJson(Map<String, dynamic> json) {
    return AttendanceReportResult(
      matchId: json['match_id'] as String? ?? '',
      attended: json['attended'] as bool? ?? false,
      reportedAt: _parseDateTime(json['reported_at']),
      deadline: _parseDateTime(json['deadline']),
      error: json['error'] as String?,
    );
  }

  /// The match identifier.
  final String matchId;

  /// Whether the user reported attending.
  final bool attended;

  /// When the report was submitted.
  final DateTime? reportedAt;

  /// The reporting deadline when available.
  final DateTime? deadline;

  /// The error returned by the RPC when available.
  final String? error;

  /// Converts the result to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'match_id': matchId,
      'attended': attended,
      'reported_at': reportedAt?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'error': error,
    };
  }
}

/// Represents the result of submitting dinner feedback.
class FeedbackSubmissionResult {
  /// Creates a feedback submission result.
  const FeedbackSubmissionResult({required this.feedbackId, this.error});

  /// Creates a feedback submission result from serialized JSON.
  factory FeedbackSubmissionResult.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmissionResult(
      feedbackId: json['feedback_id'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  /// The feedback identifier.
  final String feedbackId;

  /// The error returned by the RPC when available.
  final String? error;

  /// Converts the result to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'feedback_id': feedbackId,
      'error': error,
    };
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
