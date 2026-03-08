/// Represents the full home dashboard payload rendered in the shell feed.
class HomeDashboardView {
  /// Creates a home dashboard view payload.
  const HomeDashboardView({
    required this.city,
    required this.userInitials,
    required this.quickActionsPrompt,
    required this.openSeatsPrompt,
    required this.openSeats,
    required this.activeCircleCount,
    this.confirmedDinner,
  });

  /// Creates a home dashboard payload from serialized data.
  factory HomeDashboardView.fromJson(Map<String, dynamic> json) {
    return HomeDashboardView(
      city: json['city'] as String? ?? '',
      userInitials: json['user_initials'] as String? ?? '',
      quickActionsPrompt: json['quick_actions_prompt'] as String? ?? '',
      openSeatsPrompt: json['open_seats_prompt'] as String? ?? '',
      openSeats: (json['open_seats'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> seat) => HomeOpenSeat.fromJson(Map<String, dynamic>.from(seat)))
          .toList(growable: false),
      activeCircleCount: json['active_circle_count'] as int? ?? 0,
      confirmedDinner: json['confirmed_dinner'] is Map
          ? HomeConfirmedDinner.fromJson(
              Map<String, dynamic>.from(json['confirmed_dinner'] as Map),
            )
          : null,
    );
  }

  /// The currently selected city label.
  final String city;

  /// Initials shown in the top-left avatar.
  final String userInitials;

  /// Luma prompt shown above quick actions.
  final String quickActionsPrompt;

  /// Luma prompt shown above open seats.
  final String openSeatsPrompt;

  /// Available open-seat opportunities.
  final List<HomeOpenSeat> openSeats;

  /// Number of circles the user is in.
  final int activeCircleCount;

  /// The next confirmed dinner summary if available.
  final HomeConfirmedDinner? confirmedDinner;

  /// Converts the payload to serialized JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'city': city,
      'user_initials': userInitials,
      'quick_actions_prompt': quickActionsPrompt,
      'open_seats_prompt': openSeatsPrompt,
      'open_seats': openSeats.map((HomeOpenSeat seat) => seat.toJson()).toList(growable: false),
      'active_circle_count': activeCircleCount,
      'confirmed_dinner': confirmedDinner?.toJson(),
    };
  }

  /// Returns a modified copy of this payload.
  HomeDashboardView copyWith({
    String? city,
    String? userInitials,
    String? quickActionsPrompt,
    String? openSeatsPrompt,
    List<HomeOpenSeat>? openSeats,
    int? activeCircleCount,
    HomeConfirmedDinner? confirmedDinner,
  }) {
    return HomeDashboardView(
      city: city ?? this.city,
      userInitials: userInitials ?? this.userInitials,
      quickActionsPrompt: quickActionsPrompt ?? this.quickActionsPrompt,
      openSeatsPrompt: openSeatsPrompt ?? this.openSeatsPrompt,
      openSeats: openSeats ?? this.openSeats,
      activeCircleCount: activeCircleCount ?? this.activeCircleCount,
      confirmedDinner: confirmedDinner ?? this.confirmedDinner,
    );
  }
}

/// Represents the confirmed dinner summary card on the home dashboard.
class HomeConfirmedDinner {
  /// Creates a confirmed dinner summary.
  const HomeConfirmedDinner({
    required this.badge,
    required this.dateLabel,
    required this.timeLabel,
    required this.venue,
    required this.city,
  });

  /// Creates a confirmed dinner summary from serialized data.
  factory HomeConfirmedDinner.fromJson(Map<String, dynamic> json) {
    return HomeConfirmedDinner(
      badge: json['badge'] as String? ?? '',
      dateLabel: json['date_label'] as String? ?? '',
      timeLabel: json['time_label'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  /// Top badge line shown in the card.
  final String badge;

  /// Date line.
  final String dateLabel;

  /// Time line.
  final String timeLabel;

  /// Venue name.
  final String venue;

  /// Venue city.
  final String city;

  /// Converts this summary to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'badge': badge,
      'date_label': dateLabel,
      'time_label': timeLabel,
      'venue': venue,
      'city': city,
    };
  }

  /// Returns a modified copy of this summary.
  HomeConfirmedDinner copyWith({
    String? badge,
    String? dateLabel,
    String? timeLabel,
    String? venue,
    String? city,
  }) {
    return HomeConfirmedDinner(
      badge: badge ?? this.badge,
      dateLabel: dateLabel ?? this.dateLabel,
      timeLabel: timeLabel ?? this.timeLabel,
      venue: venue ?? this.venue,
      city: city ?? this.city,
    );
  }
}

/// Represents a single open-seat dinner card on the home rail.
class HomeOpenSeat {
  /// Creates an open-seat card payload.
  const HomeOpenSeat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.seatsLeft,
    this.isHot = false,
  });

  /// Creates an open-seat card from serialized data.
  factory HomeOpenSeat.fromJson(Map<String, dynamic> json) {
    return HomeOpenSeat(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      seatsLeft: json['seats_left'] as int? ?? 0,
      isHot: json['is_hot'] as bool? ?? false,
    );
  }

  /// Unique seat id.
  final String id;

  /// Card title.
  final String title;

  /// Card subtitle.
  final String subtitle;

  /// Remaining seats count.
  final int seatsLeft;

  /// Whether the card should render with a hot gradient.
  final bool isHot;

  /// Converts the seat card payload to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'seats_left': seatsLeft,
      'is_hot': isHot,
    };
  }

  /// Returns a modified copy of this seat payload.
  HomeOpenSeat copyWith({
    String? id,
    String? title,
    String? subtitle,
    int? seatsLeft,
    bool? isHot,
  }) {
    return HomeOpenSeat(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      isHot: isHot ?? this.isHot,
    );
  }
}
