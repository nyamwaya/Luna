import '../../models/dinner_event.dart';
import '../../models/dinner_invite.dart';
import '../../models/dinner_match.dart';
import '../../models/guest_dinner_event_view.dart';
import '../../models/match_detail.dart';
import '../../models/match_guest.dart';
import '../../models/user_profile.dart';
import 'conversation_shell_state.dart';

/// Provides preview payloads for shell foundation states.
abstract final class ConversationShellPreviewData {
  /// Returns preview payload data for a shell widget.
  static Map<String, dynamic> dataFor(ShellWidget widget) {
    return switch (widget) {
      ShellWidget.none => const <String, dynamic>{},
      ShellWidget.dinnerInvite => _buildDinnerInvite().toJson(),
      ShellWidget.waitingForPairs => _buildGuestEventView().toJson(),
      ShellWidget.pairReveal => _buildPairRevealDetail().toJson(),
      ShellWidget.waitingForPartner => _buildWaitingForPartnerDetail().toJson(),
      ShellWidget.partnerDeclined => _buildPartnerDeclinedDetail().toJson(),
      ShellWidget.confirmedDinner => _buildConfirmedDetail().toJson(),
      ShellWidget.checkIn => _buildConfirmedDetail().toJson(),
      ShellWidget.attendanceReport => _buildConfirmedDetail().toJson(),
      ShellWidget.feedback => _buildCompletedDetail().toJson(),
    };
  }

  static DinnerInvite _buildDinnerInvite() {
    return DinnerInvite(
      id: 'invite-preview',
      status: InviteStatus.pending,
      dinnerEventId: 'event-preview',
      eventTitle: 'Thursday Dinner at Spoon & Stable',
      scheduledDate: DateTime(2026, 3, 19, 19, 30),
      venue: 'Spoon & Stable',
      venueAddress: '211 N 1st St, Minneapolis, MN 55401',
      circleName: 'Rec Center Ballers',
      hostId: 'host-1',
      acceptedCount: 4,
      acceptedAvatars: const <UserProfile>[
        UserProfile(id: 'guest-1', firstName: 'Priya'),
        UserProfile(id: 'guest-2', firstName: 'Jordan'),
      ],
      eventStatus: DinnerEventStatus.inviting,
    );
  }

  static GuestDinnerEventView _buildGuestEventView() {
    return GuestDinnerEventView(
      event: DinnerEvent(
        id: 'event-preview',
        title: 'Thursday Dinner at Spoon & Stable',
        scheduledDate: DateTime(2026, 3, 19, 19, 30),
        venue: 'Spoon & Stable',
        venueAddress: '211 N 1st St, Minneapolis, MN 55401',
        status: DinnerEventStatus.pairing,
        circleName: 'Rec Center Ballers',
        checkinOpenHours: 1,
        checkinCloseHours: 2,
      ),
      invite: DinnerInvite(
        id: 'invite-preview',
        status: InviteStatus.accepted,
        dinnerEventId: 'event-preview',
        eventTitle: 'Thursday Dinner at Spoon & Stable',
        scheduledDate: DateTime(2026, 3, 19, 19, 30),
        venue: 'Spoon & Stable',
        venueAddress: '211 N 1st St, Minneapolis, MN 55401',
        circleName: 'Rec Center Ballers',
        acceptedCount: 6,
        eventStatus: DinnerEventStatus.pairing,
      ),
      match: DinnerMatch(
        id: 'match-preview',
        dinnerEventId: 'event-preview',
        status: MatchStatus.pending,
        revealAt: DateTime(2026, 3, 18, 18, 0),
        createdAt: DateTime(2026, 3, 17, 12, 0),
        updatedAt: DateTime(2026, 3, 17, 12, 0),
      ),
      myConfirmed: false,
      partnerConfirmed: false,
      checkIn: const DinnerEventCheckInState(eligible: false),
    );
  }

  static MatchDetail _buildPairRevealDetail() {
    return MatchDetail(
      match: DinnerMatch(
        id: 'match-preview',
        dinnerEventId: 'event-preview',
        status: MatchStatus.revealed,
        revealAt: DateTime(2026, 3, 18, 18, 0),
        createdAt: DateTime(2026, 3, 17, 12, 0),
        updatedAt: DateTime(2026, 3, 18, 18, 0),
      ),
      event: DinnerEvent(
        id: 'event-preview',
        title: 'Thursday Dinner at Spoon & Stable',
        scheduledDate: DateTime(2026, 3, 19, 19, 30),
        venue: 'Spoon & Stable',
        venueAddress: '211 N 1st St, Minneapolis, MN 55401',
        status: DinnerEventStatus.paired,
        circleName: 'Rec Center Ballers',
      ),
      me: const MatchGuest(userId: 'me-1', confirmed: false, checkedIn: false),
      circle: const CircleSummary(id: 'circle-1', name: 'Rec Center Ballers'),
      partner: MatchPartnerDetail(
        profile: const UserProfile(
          id: 'partner-1',
          firstName: 'Priya',
          lastName: 'Sharma',
          occupation: 'Product Designer',
          bio: 'Loves basketball, food crawls, and trying new patios.',
        ),
        sharedInterests: const <String>['Basketball', 'Travel', 'Restaurants'],
        confirmed: false,
      ),
      feedbackSubmitted: false,
    );
  }

  static MatchDetail _buildWaitingForPartnerDetail() {
    return _buildPairRevealDetail().copyWith(
      me: const MatchGuest(userId: 'me-1', confirmed: true, checkedIn: false),
    );
  }

  static MatchDetail _buildPartnerDeclinedDetail() {
    return _buildPairRevealDetail().copyWith(
      match: _buildPairRevealDetail().match.copyWith(status: MatchStatus.cancelled),
      me: const MatchGuest(userId: 'me-1', confirmed: true, checkedIn: false),
      partner: _buildPairRevealDetail().partner?.copyWith(
        declinedAt: DateTime(2026, 3, 18, 19, 15),
      ),
    );
  }

  static MatchDetail _buildConfirmedDetail() {
    return _buildPairRevealDetail().copyWith(
      match: _buildPairRevealDetail().match.copyWith(status: MatchStatus.confirmed),
      me: const MatchGuest(userId: 'me-1', confirmed: true, checkedIn: false),
      partner: _buildPairRevealDetail().partner?.copyWith(confirmed: true),
      event: _buildPairRevealDetail().event.copyWith(
        status: DinnerEventStatus.paired,
        checkinWindowOpensAt: DateTime(2026, 3, 19, 18, 30),
        checkinWindowClosesAt: DateTime(2026, 3, 19, 21, 30),
      ),
    );
  }

  static MatchDetail _buildCompletedDetail() {
    return _buildConfirmedDetail().copyWith(
      match: _buildConfirmedDetail().match.copyWith(status: MatchStatus.completed),
      me: const MatchGuest(
        userId: 'me-1',
        confirmed: true,
        attended: true,
        checkedIn: true,
      ),
      partner: _buildConfirmedDetail().partner?.copyWith(
        confirmed: true,
        checkedIn: true,
      ),
    );
  }
}
