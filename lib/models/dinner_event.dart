/// Represents the lifecycle state of a dinner event.
enum DinnerEventStatus {
  /// Event exists but is not yet active.
  draft('draft'),

  /// Invites are being sent or collected.
  inviting('inviting'),

  /// Pairing is currently in progress.
  pairing('pairing'),

  /// Pairing has completed.
  paired('paired'),

  /// Dinner is currently underway.
  inProgress('in_progress'),

  /// Dinner event has concluded.
  completed('completed'),

  /// Dinner event was cancelled.
  cancelled('cancelled'),

  /// Fallback for unsupported values.
  unknown('unknown');

  /// Creates an event status.
  const DinnerEventStatus(this.value);

  /// The serialized value for the status.
  final String value;

  /// Parses a serialized event status.
  static DinnerEventStatus fromString(String? value) {
    return DinnerEventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DinnerEventStatus.unknown,
    );
  }
}

/// Represents a dinner event used by the pairing flow.
class DinnerEvent {
  /// Creates a dinner event.
  const DinnerEvent({
    required this.id,
    required this.title,
    this.scheduledDate,
    this.venue,
    this.venueAddress,
    this.venueLat,
    this.venueLng,
    required this.status,
    this.circleName,
    this.reportingDeadline,
    this.cancellationPolicy,
    this.checkinOpenHours = 1,
    this.checkinCloseHours = 2,
    this.checkinWindowOpensAt,
    this.checkinWindowClosesAt,
  });

  /// Creates a dinner event from serialized JSON.
  factory DinnerEvent.fromJson(Map<String, dynamic> json) {
    return DinnerEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['event_title'] as String? ?? '',
      scheduledDate: _parseDateTime(json['scheduled_date']),
      venue: json['venue'] as String?,
      venueAddress: json['venue_address'] as String?,
      venueLat: _parseDouble(json['venue_lat']),
      venueLng: _parseDouble(json['venue_lng']),
      status: DinnerEventStatus.fromString(json['status'] as String?),
      circleName: json['circle_name'] as String?,
      reportingDeadline: _parseDateTime(json['reporting_deadline']),
      cancellationPolicy: json['cancellation_policy'] as String?,
      checkinOpenHours: (json['checkin_open_hours'] as num?)?.toInt() ?? 1,
      checkinCloseHours: (json['checkin_close_hours'] as num?)?.toInt() ?? 2,
      checkinWindowOpensAt: _parseDateTime(
        json['checkin_window_opens_at'] ?? json['window_opens_at'],
      ),
      checkinWindowClosesAt: _parseDateTime(
        json['checkin_window_closes_at'] ?? json['window_closes_at'],
      ),
    );
  }

  /// The unique identifier for the event.
  final String id;

  /// The event title.
  final String title;

  /// The scheduled date and time.
  final DateTime? scheduledDate;

  /// The event venue name.
  final String? venue;

  /// The event venue address.
  final String? venueAddress;

  /// The event venue latitude.
  final double? venueLat;

  /// The event venue longitude.
  final double? venueLng;

  /// The current event status.
  final DinnerEventStatus status;

  /// The associated circle name.
  final String? circleName;

  /// The attendance reporting deadline.
  final DateTime? reportingDeadline;

  /// The cancellation policy for the event.
  final String? cancellationPolicy;

  /// Hours before the dinner when check-in opens.
  final int checkinOpenHours;

  /// Hours after the dinner when check-in closes.
  final int checkinCloseHours;

  /// The computed check-in window opening time.
  final DateTime? checkinWindowOpensAt;

  /// The computed check-in window closing time.
  final DateTime? checkinWindowClosesAt;

  /// Converts the event to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'venue': venue,
      'venue_address': venueAddress,
      'venue_lat': venueLat,
      'venue_lng': venueLng,
      'status': status.value,
      'circle_name': circleName,
      'reporting_deadline': reportingDeadline?.toIso8601String(),
      'cancellation_policy': cancellationPolicy,
      'checkin_open_hours': checkinOpenHours,
      'checkin_close_hours': checkinCloseHours,
      'checkin_window_opens_at': checkinWindowOpensAt?.toIso8601String(),
      'checkin_window_closes_at': checkinWindowClosesAt?.toIso8601String(),
    };
  }

  /// Creates a modified copy of the event.
  DinnerEvent copyWith({
    String? id,
    String? title,
    DateTime? scheduledDate,
    String? venue,
    String? venueAddress,
    double? venueLat,
    double? venueLng,
    DinnerEventStatus? status,
    String? circleName,
    DateTime? reportingDeadline,
    String? cancellationPolicy,
    int? checkinOpenHours,
    int? checkinCloseHours,
    DateTime? checkinWindowOpensAt,
    DateTime? checkinWindowClosesAt,
  }) {
    return DinnerEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      venueLat: venueLat ?? this.venueLat,
      venueLng: venueLng ?? this.venueLng,
      status: status ?? this.status,
      circleName: circleName ?? this.circleName,
      reportingDeadline: reportingDeadline ?? this.reportingDeadline,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      checkinOpenHours: checkinOpenHours ?? this.checkinOpenHours,
      checkinCloseHours: checkinCloseHours ?? this.checkinCloseHours,
      checkinWindowOpensAt: checkinWindowOpensAt ?? this.checkinWindowOpensAt,
      checkinWindowClosesAt: checkinWindowClosesAt ?? this.checkinWindowClosesAt,
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

double? _parseDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}
