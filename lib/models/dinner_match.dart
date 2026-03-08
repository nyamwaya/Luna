/// Represents the lifecycle state of a dinner match.
enum MatchStatus {
  /// Match created before reveal time.
  pending('pending'),

  /// Match is visible to guests.
  revealed('revealed'),

  /// Both guests have confirmed.
  confirmed('confirmed'),

  /// Dinner has been completed.
  completed('completed'),

  /// Reporting deadline passed with no final resolution.
  expired('expired'),

  /// Match was cancelled.
  cancelled('cancelled'),

  /// Fallback for unsupported values.
  unknown('unknown');

  /// Creates a status value.
  const MatchStatus(this.value);

  /// The serialized value for this status.
  final String value;

  /// Parses a serialized match status.
  static MatchStatus fromString(String? value) {
    return MatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchStatus.unknown,
    );
  }
}

/// Represents a dinner match row.
class DinnerMatch {
  /// Creates a dinner match.
  const DinnerMatch({
    required this.id,
    required this.dinnerEventId,
    required this.status,
    this.revealAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a dinner match from serialized JSON.
  factory DinnerMatch.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();

    return DinnerMatch(
      id: json['id'] as String? ?? '',
      dinnerEventId: json['dinner_event_id'] as String? ?? '',
      status: MatchStatus.fromString(json['status'] as String?),
      revealAt: _parseDateTime(json['reveal_at']),
      createdAt: _parseDateTime(json['created_at']) ?? now,
      updatedAt: _parseDateTime(json['updated_at']) ?? now,
    );
  }

  /// The unique identifier for the match.
  final String id;

  /// The parent dinner event identifier.
  final String dinnerEventId;

  /// The current match status.
  final MatchStatus status;

  /// The timestamp that controls reveal gating.
  final DateTime? revealAt;

  /// The created timestamp.
  final DateTime createdAt;

  /// The updated timestamp.
  final DateTime updatedAt;

  /// Converts the match to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'dinner_event_id': dinnerEventId,
      'status': status.value,
      'reveal_at': revealAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a modified copy of the match.
  DinnerMatch copyWith({
    String? id,
    String? dinnerEventId,
    MatchStatus? status,
    DateTime? revealAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DinnerMatch(
      id: id ?? this.id,
      dinnerEventId: dinnerEventId ?? this.dinnerEventId,
      status: status ?? this.status,
      revealAt: revealAt ?? this.revealAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
