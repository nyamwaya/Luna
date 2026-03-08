import 'dinner_event.dart';
import 'user_profile.dart';

/// Represents the lifecycle state of a dinner invite.
enum InviteStatus {
  /// Invite has not yet been answered.
  pending('pending'),

  /// Invite was accepted.
  accepted('accepted'),

  /// Invite was declined.
  declined('declined'),

  /// Fallback for unsupported values.
  unknown('unknown');

  /// Creates an invite status.
  const InviteStatus(this.value);

  /// The serialized value for the status.
  final String value;

  /// Parses a serialized invite status.
  static InviteStatus fromString(String? value) {
    return InviteStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InviteStatus.unknown,
    );
  }
}

/// Represents the dinner invite payload surfaced in the shell.
class DinnerInvite {
  /// Creates a dinner invite.
  const DinnerInvite({
    required this.id,
    required this.status,
    required this.dinnerEventId,
    this.eventTitle,
    this.scheduledDate,
    this.venue,
    this.venueAddress,
    this.circleName,
    this.hostId,
    this.acceptedCount = 0,
    this.acceptedAvatars = const <UserProfile>[],
    this.eventStatus = DinnerEventStatus.unknown,
  });

  /// Creates a dinner invite from serialized JSON.
  factory DinnerInvite.fromJson(Map<String, dynamic> json) {
    final List<dynamic> avatars = (json['accepted_avatars'] as List?) ?? const <dynamic>[];

    return DinnerInvite(
      id: (json['invite_id'] ?? json['id'] ?? '') as String,
      status: InviteStatus.fromString(json['status'] as String?),
      dinnerEventId: json['dinner_event_id'] as String? ?? '',
      eventTitle: json['event_title'] as String? ?? json['title'] as String?,
      scheduledDate: _parseDateTime(json['scheduled_date']),
      venue: json['venue'] as String?,
      venueAddress: json['venue_address'] as String?,
      circleName: json['circle_name'] as String?,
      hostId: json['host_id'] as String?,
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      acceptedAvatars: avatars
          .whereType<Map>()
          .map(
            (avatar) => UserProfile.fromJson(
              Map<String, dynamic>.from(avatar),
            ),
          )
          .toList(growable: false),
      eventStatus: DinnerEventStatus.fromString(json['event_status'] as String?),
    );
  }

  /// The unique identifier for the invite.
  final String id;

  /// The invite status.
  final InviteStatus status;

  /// The associated dinner event identifier.
  final String dinnerEventId;

  /// The event title when available.
  final String? eventTitle;

  /// The scheduled date for the event.
  final DateTime? scheduledDate;

  /// The venue name.
  final String? venue;

  /// The venue address.
  final String? venueAddress;

  /// The circle name.
  final String? circleName;

  /// The host user identifier.
  final String? hostId;

  /// The number of accepted guests.
  final int acceptedCount;

  /// A small set of accepted guest avatars.
  final List<UserProfile> acceptedAvatars;

  /// The current status of the underlying event when available.
  final DinnerEventStatus eventStatus;

  /// Converts the invite to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'invite_id': id,
      'status': status.value,
      'dinner_event_id': dinnerEventId,
      'event_title': eventTitle,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'venue': venue,
      'venue_address': venueAddress,
      'circle_name': circleName,
      'host_id': hostId,
      'accepted_count': acceptedCount,
      'accepted_avatars': acceptedAvatars.map((avatar) => avatar.toJson()).toList(),
      'event_status': eventStatus.value,
    };
  }

  /// Creates a modified copy of the invite.
  DinnerInvite copyWith({
    String? id,
    InviteStatus? status,
    String? dinnerEventId,
    String? eventTitle,
    DateTime? scheduledDate,
    String? venue,
    String? venueAddress,
    String? circleName,
    String? hostId,
    int? acceptedCount,
    List<UserProfile>? acceptedAvatars,
    DinnerEventStatus? eventStatus,
  }) {
    return DinnerInvite(
      id: id ?? this.id,
      status: status ?? this.status,
      dinnerEventId: dinnerEventId ?? this.dinnerEventId,
      eventTitle: eventTitle ?? this.eventTitle,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      circleName: circleName ?? this.circleName,
      hostId: hostId ?? this.hostId,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      acceptedAvatars: acceptedAvatars ?? this.acceptedAvatars,
      eventStatus: eventStatus ?? this.eventStatus,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
