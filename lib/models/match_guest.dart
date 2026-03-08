/// Represents the current user's or partner's per-match guest state.
class MatchGuest {
  /// Creates a match guest state.
  const MatchGuest({
    required this.userId,
    this.confirmed = false,
    this.confirmedAt,
    this.declinedAt,
    this.attended,
    this.reportedAt,
    this.checkedIn = false,
  });

  /// Creates a match guest state from serialized JSON.
  factory MatchGuest.fromJson(Map<String, dynamic> json) {
    return MatchGuest(
      userId: (json['user_id'] ?? json['id'] ?? '') as String,
      confirmed: json['confirmed'] as bool? ?? false,
      confirmedAt: _parseDateTime(json['confirmed_at']),
      declinedAt: _parseDateTime(json['declined_at']),
      attended: json['attended'] as bool?,
      reportedAt: _parseDateTime(json['reported_at']),
      checkedIn: json['checked_in'] as bool? ?? false,
    );
  }

  /// The user identifier for the guest row.
  final String userId;

  /// Whether the guest has confirmed attendance.
  final bool confirmed;

  /// When the guest confirmed attendance.
  final DateTime? confirmedAt;

  /// When the guest declined the match.
  final DateTime? declinedAt;

  /// Whether the guest reported attending.
  final bool? attended;

  /// When attendance was reported.
  final DateTime? reportedAt;

  /// Whether the guest has checked in.
  final bool checkedIn;

  /// Converts the guest state to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'confirmed': confirmed,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'declined_at': declinedAt?.toIso8601String(),
      'attended': attended,
      'reported_at': reportedAt?.toIso8601String(),
      'checked_in': checkedIn,
    };
  }

  /// Creates a modified copy of the guest state.
  MatchGuest copyWith({
    String? userId,
    bool? confirmed,
    DateTime? confirmedAt,
    DateTime? declinedAt,
    bool? attended,
    DateTime? reportedAt,
    bool? checkedIn,
  }) {
    return MatchGuest(
      userId: userId ?? this.userId,
      confirmed: confirmed ?? this.confirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      attended: attended ?? this.attended,
      reportedAt: reportedAt ?? this.reportedAt,
      checkedIn: checkedIn ?? this.checkedIn,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
