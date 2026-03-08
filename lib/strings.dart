class Strings {
  static const String appTitle = 'Luma';
  static const String backLabel = 'Back';
  static const String expandLabel = 'Expand ›';
  static const String newConversationLabel = 'New conversation';
  static const String previewStatesLabel = 'Preview states';
  static const String headerHome = 'HOME';
  static const String shellIntroMessage =
      'I can walk you through every dinner pairing state from here.';
  static const String shellDinnerInviteMessage =
      'You\'ve been invited to a dinner by Marcus. Want to join the pool?';
  static const String shellWaitingForPairsMessage =
      'You\'re in the pool. Pairs drop in 4 days — I\'ll notify you the moment yours is ready.';
  static const String shellPairRevealMessage =
      'Your dinner partner is here. You and Priya share a lot in common — confirm to lock it in.';
  static const String shellWaitingForPartnerMessage =
      'You\'re confirmed. Waiting for Priya to confirm her side — I\'ll let you know as soon as she does.';
  static const String shellPartnerDeclinedMessage =
      'Priya can\'t make this one. You\'ve been re-added to the pool — I\'ll find you a new match if there\'s someone available.';
  static const String shellConfirmedDinnerMessage =
      'You\'re both in. Priya confirmed too — see you Thursday at Spoon & Stable.';
  static const String shellCheckInMessage =
      'You\'re near Spoon & Stable. Check in to let Priya know you\'re here.';
  static const String shellAttendanceReportMessage =
      'Hope the evening was great. Did you make it to dinner?';
  static const String shellFeedbackMessage =
      'Glad you went. How was the dinner with Priya?';
  static const String shellContextLabel = 'Pairing foundation preview';
  static const String shellPreviewPrompt = 'Preview shell states';
  static const String shellSectionLabel = 'LUMA';

  static const String headerInvitePending = 'INVITE · PENDING';
  static const String headerInviteAccepted = 'INVITE · ACCEPTED';
  static const String headerMatchRevealed = 'MATCH · REVEALED';
  static const String headerMatchPending = 'MATCH · PENDING';
  static const String headerMatchCancelled = 'MATCH · CANCELLED';
  static const String headerDinnerConfirmed = 'DINNER · CONFIRMED';
  static const String headerDinnerCheckIn = 'DINNER · CHECK IN';
  static const String headerPostDinner = 'POST-DINNER';
  static const String headerFeedback = 'FEEDBACK';

  static const String notificationNew = 'Just now · New notification';
  static const String notificationAcceptedInvite = 'Just now · Accepted invite';
  static const String notificationPairReady = 'Just now · Your pair is ready';
  static const String notificationConfirmedMatch = 'Just now · Confirmed your match';
  static const String notificationMatchUpdate = 'Just now · Match update';
  static const String notificationTonightDinner = 'Tonight · Mar 19 · Spoon & Stable';
  static const String notificationPostDinner = 'Mar 19 · Spoon & Stable';

  static const String askAboutDinnerPlaceholder = 'Ask about this dinner...';
  static const String askAboutYourDinnerPlaceholder = 'Ask about your dinner...';
  static const String saySomethingPlaceholder = 'Or say something...';
  static const String addNotePlaceholder = 'Add a note about the evening...';
  static const String homeComposerPlaceholder =
      'Set my availability for next week...';
  static const String realtimeConnectionIssueMessage =
      'I hit a realtime sync issue. Try sending again in a moment.';
  static const String sendMessageFailedMessage =
      'I could not process that right now. Please try again.';
  static const String conversationResetFailedMessage =
      'I could not start a new conversation right now. Please try again.';
  static const String assistantMyCirclesTitle = 'My circles';
  static const String assistantDinnersTitle = 'Dinners';
  static const String assistantCircleDetailTitle = 'Circle details';
  static const String assistantNoCirclesMessage = 'No circles yet.';
  static const String assistantNoDinnersMessage = 'Nothing scheduled yet.';
  static const String assistantCircleFallbackName = 'Circle';
  static const String assistantDinnerFallbackName = 'Dinner';
  static const String assistantMemberFallbackName = 'Member';
  static const String assistantInviteCodeLabel = 'Invite code';

  // Home dashboard
  static const String homePrimaryMessage =
      'This is your home dashboard. I will keep it updated with your dinners, circles, and next actions.';
  static const String homeCity = 'Minneapolis';
  static const String homeOpenSeatsPrompt =
      '4 dinners near you still have open seats this week.';
  static const String homeQuickActionsPrompt = 'What do you want to do?';
  static const String homeDetailsCta = 'Details →';
  static const String homeRequestSeatCta = 'Request Seat';
  static const String homeSeatLeftSuffix = 'left';
  static const String homeFindDinner = 'Find a Dinner';
  static const String homeFindDinnerSubtitle = 'Set your availability';
  static const String homeMyCircles = 'My Circles';
  static const String homeMyCirclesSubtitle = '3 active groups';
  static const String homeStartCircle = 'Start a Circle';
  static const String homeStartCircleSubtitle = 'Invite your people';
  static const String homeMyProfile = 'My Profile';
  static const String homeMyProfileSubtitle = 'Interests & preferences';
  static const String homeConfirmedBadge = 'REC CENTER BALLERS · ✓ CONFIRMED';
  static const String homeConfirmedDate = 'Thursday, Mar 19th';
  static const String homeConfirmedTime = '7:30 PM';
  static const String homeConfirmedVenue = 'Spoon & Stable';
  static const String homeConfirmedVenueCity = 'Minneapolis';
  static const String homeSeatMplsFoodies = 'MPLS Foodies';
  static const String homeSeatMplsFoodiesDate = 'Fri Mar 20 · 7 PM';
  static const String homeSeatNorthsideRunners = 'Northside Runners';
  static const String homeSeatNorthsideRunnersDate = 'Sat Mar 22 · 8 PM';
  static const String homeSeatUptownBrunchClub = 'Uptown Brunch Club';
  static const String homeSeatUptownBrunchClubDate = 'Sun Mar 23 · 11 AM';
  static const String homeFindDinnerTapped =
      'Great — let\'s set your availability for this week.';
  static const String homeMyCirclesTapped =
      'Opening your circles. Want member view or admin view first?';
  static const String homeStartCircleTapped =
      'Perfect. I can help you start a new circle in a few steps.';
  static const String homeMyProfileTapped =
      'Opening your profile preferences and interests.';
  static const String homeDinnerDetailsTapped =
      'Here are your confirmed dinner details.';
  static const String homeSeatRequested =
      'Nice pick. I\'ve marked your request for this open seat.';
  static const String homeHistoryDrawerTitle = 'Earlier conversation';

  static String homeHistorySummaryLabel(int count) =>
      'Earlier · $count message${count == 1 ? '' : 's'} hidden';

  // Pairing flow
  static const String dinnerInviteTitle = 'You have a dinner invite.';
  static const String dinnerInviteSubtitle =
      'Review the details and decide if you want in.';
  static const String waitingForPairsTitle = 'You are in for dinner.';
  static const String waitingForPairsSubtitle =
      'I will reveal your partner once matching closes.';
  static const String pairRevealTitle = 'Your dinner partner is here.';
  static const String pairRevealSubtitle = 'Confirm to lock it in.';
  static const String confirmCta = "Confirm I'll be there";
  static const String declineCta = "Can't make it";
  static const String waitingForPartner = 'Waiting for your partner to confirm.';
  static const String waitingForPartnerSubtitle =
      'You are locked in. I will update you as soon as they respond.';
  static const String partnerDeclined = "Your dinner partner can't make it this time.";
  static const String partnerDeclinedSubtitle =
      'You can stay in the pool or skip this dinner round.';
  static const String requeuedMessage = "You've been re-added to the pool.";
  static const String confirmedDinnerTitle = 'Dinner is confirmed.';
  static const String confirmedDinnerSubtitle =
      'Here is everything you need for the night.';
  static const String checkInTitle = 'Check in when you arrive.';
  static const String checkInSubtitle =
      'Use this once you are near the restaurant.';

  static const String acceptInviteCta = 'Accept invite';
  static const String declineInviteCta = 'Decline invite';
  static const String cancelSpotCta = 'Cancel my spot';
  static const String keepMeInCta = 'Keep me in the pool';
  static const String skipRoundCta = 'Skip this round';
  static const String addToCalendarCta = 'Add to calendar';
  static const String checkInCta = 'Check in';
  static const String cantGoCta = "I can't go";
  static const String getDirectionsCta = 'Get directions ↗';
  static const String nudgeThemCta = 'Nudge them';
  static const String notNowCtaPlain = 'Not now';
  static const String confirmedBadge = '✓ Confirmed';
  static const String mapPreviewLabel = 'MAP PREVIEW';
  static const String withinRangeStatus = "You're within range";
  static const String notYetStatus = 'Not yet';
  static const String lookingForNewPair = 'Looking for a new pair...';
  static const String unmatchedCountLabel = '2 unmatched';
  static const String checkInOpensSoon = 'Opens Mar 19';

  // Attendance
  static const String attendancePrompt = 'Did you make it to dinner?';
  static const String attendedYes = 'Yes, I went';
  static const String attendedNo = "Couldn't make it";
  static const String flakeWarning = 'Reporting a no-show will affect your reliability score.';
  static const String attendanceWindowMessage =
      'Reporting window closes Saturday, Mar 22 at 7:30 PM.';

  // Feedback
  static const String feedbackPrompt = 'How was the dinner?';
  static const String feedbackSubtitle =
      'Share a quick read on the night so we can improve future matches.';
  static const String feedbackSubmitCta = 'Submit feedback';
  static const String feedbackPhotoPrompt = 'Add a photo to circle memories?';
  static const String tapToRate = 'Tap to rate';
  static const String tagGreatConversation = 'Great conversation';
  static const String tagFeltAwkward = 'Felt awkward';
  static const String tagPerfectVenue = 'Perfect venue';
  static const String tagTooLoud = 'Too loud';
  static const String tagWouldMeetAgain = 'Would meet again';
  static const String tagTooShort = 'Too short';
  static const String tagGreatFood = 'Great food';

  // Labels
  static const String eventLabel = 'Event';
  static const String whenLabel = 'When';
  static const String whereLabel = 'Where';
  static const String venueLabel = 'Venue';
  static const String circleLabel = 'Circle';
  static const String revealAtLabel = 'Reveal at';
  static const String partnerLabel = 'Partner';
  static const String occupationLabel = 'Occupation';
  static const String sharedInterestsLabel = 'Shared interests';
  static const String acceptedCountLabel = 'Accepted guests';
  static const String confirmationStatusLabel = 'Status';
  static const String policyLabel = 'Policy';
  static const String windowOpensLabel = 'Window opens';
  static const String windowClosesLabel = 'Window closes';
  static const String partnerCheckInLabel = 'Partner check-in';
  static const String feedbackStatusLabel = 'Feedback';
  static const String acceptedShortLabel = 'accepted';
  static const String guestCountShortLabel = 'guests';
  static const String pendingConfirmationLabel = "Priya hasn't confirmed yet";
  static const String checkInStatusLabel = 'Check-in status';
  static const String noShowImpactLabel =
      'Reporting a no-show will affect your reliability score, which influences future pairings.';

  // Status values
  static const String valuePending = 'Pending';
  static const String partnerPendingStatus = 'Waiting on partner';
  static const String partnerCheckedInStatus = 'Checked in';
  static const String feedbackSubmittedStatus = 'Submitted';
  static const String feedbackPendingStatus = 'Not submitted';

  // Preview labels
  static const String previewInvite = 'Invite';
  static const String previewHome = 'Home';
  static const String previewWaiting = 'Waiting';
  static const String previewReveal = 'Reveal';
  static const String previewPartner = 'Partner';
  static const String previewDeclined = 'Declined';
  static const String previewConfirmed = 'Confirmed';
  static const String previewCheckIn = 'Check-in';
  static const String previewAttendance = 'Attendance';
  static const String previewFeedback = 'Feedback';

  // Circles
  static const String circleFoundTitle = 'Found it. Want to join?';
  static const String joinCircleCta = 'Join this circle →';
  static const String notNowCta = 'Not now';
  static const String createCircleCta = 'Create Circle →';
  static const String copyCodeCta = 'Copy Code';
  static const String shareBadgeCta = 'Share Badge ↗';

  static String homeActiveGroupsLabel(int count) => '$count active groups';

  static String homeSeatsLeftLabel(int count) => '$count $homeSeatLeftSuffix';
}
