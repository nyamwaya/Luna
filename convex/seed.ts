import { mutation } from './_generated/server';

const demoViewerUserId = 'local-demo-user';
const legacyDemoViewerUserId = 'user_aleck_seed';

export const seedDummyData = mutation({
  args: {},
  handler: async (ctx) => {
    const now = Date.now();
    const day = 24 * 60 * 60 * 1000;
    const hour = 60 * 60 * 1000;

    // ── Users ──────────────────────────────────────────────

    const aleckId = await upsertDemoViewerUser(ctx, {
      clerkId: demoViewerUserId,
      firstName: 'Aleck',
      lastName: 'Son',
      username: 'aleckson',
      email: 'aleck@test.com',
      bio: 'Rec league regular. Bad at free throws, great at tacos.',
      occupation: 'Product Designer',
      city: 'Minneapolis',
      lat: 44.9778,
      lng: -93.265,
      flakeScore: 5,
      dinnersAttended: 8,
      dinnersInvited: 9,
      unreadNotificationsCount: 2,
      invitesSentCount: 4,
      hasJoinedCircle: true,
      availabilityDates: ['2026-03-20', '2026-03-21', '2026-03-22'],
      interests: ['basketball', 'tacos', 'design', 'coffee'],
      createdAt: now,
      updatedAt: now,
    });

    const marcusId = await upsertUser(ctx, {
      clerkId: 'user_marcus_seed',
      firstName: 'Marcus',
      lastName: 'Williams',
      username: 'marcusw',
      email: 'marcus@test.com',
      bio: 'Point guard energy, software engineer by day.',
      occupation: 'Software Engineer',
      city: 'Minneapolis',
      lat: 44.982,
      lng: -93.27,
      flakeScore: 12,
      dinnersAttended: 6,
      dinnersInvited: 7,
      unreadNotificationsCount: 0,
      invitesSentCount: 2,
      hasJoinedCircle: true,
      availabilityDates: [],
      interests: ['basketball', 'coffee', 'startups'],
      createdAt: now,
      updatedAt: now,
    });

    const daniId = await upsertUser(ctx, {
      clerkId: 'user_dani_seed',
      firstName: 'Dani',
      lastName: 'Rivera',
      username: 'danir',
      email: 'dani@test.com',
      bio: 'Chef at heart, accountant by trade.',
      occupation: 'Accountant',
      city: 'Minneapolis',
      lat: 44.975,
      lng: -93.26,
      flakeScore: 0,
      dinnersAttended: 8,
      dinnersInvited: 8,
      unreadNotificationsCount: 1,
      invitesSentCount: 6,
      hasJoinedCircle: true,
      availabilityDates: [],
      interests: ['cooking', 'wine', 'travel'],
      createdAt: now,
      updatedAt: now,
    });

    const priyaId = await upsertUser(ctx, {
      clerkId: 'user_priya_seed',
      firstName: 'Priya',
      lastName: 'Patel',
      username: 'priyap',
      email: 'priya@test.com',
      bio: 'Data scientist. Obsessed with Ethiopian food.',
      occupation: 'Data Scientist',
      city: 'Minneapolis',
      lat: 44.98,
      lng: -93.265,
      flakeScore: 8,
      dinnersAttended: 5,
      dinnersInvited: 6,
      unreadNotificationsCount: 0,
      invitesSentCount: 1,
      hasJoinedCircle: true,
      availabilityDates: [],
      interests: ['data', 'Ethiopian food', 'running'],
      createdAt: now,
      updatedAt: now,
    });

    const jordanId = await upsertUser(ctx, {
      clerkId: 'user_jordan_seed',
      firstName: 'Jordan',
      lastName: 'Lee',
      username: 'jordanl',
      email: 'jordan@test.com',
      city: 'Minneapolis',
      lat: 44.976,
      lng: -93.268,
      flakeScore: 20,
      dinnersAttended: 4,
      dinnersInvited: 6,
      unreadNotificationsCount: 0,
      invitesSentCount: 0,
      hasJoinedCircle: true,
      availabilityDates: ['2026-03-20'],
      interests: ['photography', 'brunch', 'concerts'],
      createdAt: now,
      updatedAt: now,
    });

    // ── Circles ────────────────────────────────────────────

    const recCenterId = await upsertCircle(ctx, {
      ownerUserId: demoViewerUserId,
      name: 'Rec Center Ballers',
      vibe: 'Friends from the gym',
      city: 'Minneapolis',
      visibility: 'private',
      pairingFrequency: 'monthly',
      maxDinnerSize: 8,
      adminUserId: aleckId,
      inviteCode: 'R3CBAL',
      hashtags: ['basketball', 'sports', 'minneapolis'],
      createdAt: now - 60 * day,
      updatedAt: now,
    });

    const mplsFoodiesId = await upsertCircle(ctx, {
      ownerUserId: 'user_dani_seed',
      name: 'MPLS Foodies',
      vibe: 'Food obsessed strangers becoming friends',
      city: 'Minneapolis',
      visibility: 'public',
      pairingFrequency: 'biweekly',
      maxDinnerSize: 6,
      adminUserId: daniId,
      inviteCode: 'MPLFOD',
      hashtags: ['food', 'restaurants', 'minneapolis'],
      createdAt: now - 90 * day,
      updatedAt: now,
    });

    const fridayBookId = await upsertCircle(ctx, {
      ownerUserId: 'user_priya_seed',
      name: 'Friday Book Club',
      vibe: 'We read one book a month and eat well',
      city: 'Minneapolis',
      visibility: 'private',
      pairingFrequency: 'monthly',
      maxDinnerSize: 4,
      adminUserId: priyaId,
      inviteCode: 'FRIBK1',
      hashtags: ['books', 'reading', 'dinner'],
      createdAt: now - 120 * day,
      updatedAt: now,
    });

    // ── Circle memberships ─────────────────────────────────

    await upsertCircleMembership(ctx, {
      circleId: recCenterId,
      userId: aleckId,
      role: 'owner',
      status: 'active',
      joinedAt: now - 60 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: recCenterId,
      userId: marcusId,
      role: 'member',
      status: 'active',
      joinedAt: now - 55 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: recCenterId,
      userId: daniId,
      role: 'member',
      status: 'active',
      joinedAt: now - 50 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: recCenterId,
      userId: priyaId,
      role: 'member',
      status: 'active',
      joinedAt: now - 45 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: recCenterId,
      userId: jordanId,
      role: 'member',
      status: 'active',
      joinedAt: now - 40 * day,
    });

    await upsertCircleMembership(ctx, {
      circleId: mplsFoodiesId,
      userId: daniId,
      role: 'owner',
      status: 'active',
      joinedAt: now - 90 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: mplsFoodiesId,
      userId: aleckId,
      role: 'member',
      status: 'active',
      joinedAt: now - 30 * day,
    });

    await upsertCircleMembership(ctx, {
      circleId: fridayBookId,
      userId: priyaId,
      role: 'owner',
      status: 'active',
      joinedAt: now - 120 * day,
    });
    await upsertCircleMembership(ctx, {
      circleId: fridayBookId,
      userId: aleckId,
      role: 'member',
      status: 'active',
      joinedAt: now - 20 * day,
    });

    // ── Dinner events ──────────────────────────────────────

    const upcomingDinner1 = await upsertDinnerEvent(ctx, {
      circleId: recCenterId,
      hostUserId: aleckId,
      title: 'March Rec Center Dinner',
      venue: 'Spoon & Stable',
      venueAddress: '211 N 1st St, Minneapolis, MN 55401',
      venueLat: 44.9839,
      venueLng: -93.2729,
      scheduledDate: now + 11 * day,
      groupSize: 8,
      spotsLeft: 2,
      status: 'confirmed',
      roundNumber: 3,
      autoAdvance: true,
      cancellationPolicy: 'skip_round',
      createdAt: now - 10 * day,
      updatedAt: now,
    });

    const openDinner1 = await upsertDinnerEvent(ctx, {
      circleId: mplsFoodiesId,
      hostUserId: daniId,
      title: 'MPLS Foodies March Meetup',
      venue: 'Hai Hai',
      venueAddress: '2121 University Ave NE, Minneapolis, MN 55418',
      venueLat: 44.9924,
      venueLng: -93.2317,
      scheduledDate: now + 12 * day,
      groupSize: 6,
      spotsLeft: 2,
      status: 'open',
      roundNumber: 5,
      autoAdvance: true,
      cancellationPolicy: 'requeue',
      createdAt: now - 5 * day,
      updatedAt: now,
    });

    const openDinner2 = await upsertDinnerEvent(ctx, {
      circleId: fridayBookId,
      hostUserId: priyaId,
      title: 'Book Club Dinner — March',
      venue: 'Young Joni',
      venueAddress: '165 13th Ave NE, Minneapolis, MN 55413',
      venueLat: 44.9893,
      venueLng: -93.2484,
      scheduledDate: now + 14 * day,
      groupSize: 4,
      spotsLeft: 1,
      status: 'open',
      roundNumber: 8,
      autoAdvance: true,
      cancellationPolicy: 'skip_round',
      createdAt: now - 3 * day,
      updatedAt: now,
    });

    const openDinner3 = await upsertDinnerEvent(ctx, {
      circleId: mplsFoodiesId,
      hostUserId: daniId,
      title: 'Northside Runners Dinner',
      venue: 'Owamni',
      venueAddress: '420 1st St N, Minneapolis, MN 55401',
      venueLat: 44.9843,
      venueLng: -93.2741,
      scheduledDate: now + 14 * day,
      groupSize: 6,
      spotsLeft: 3,
      status: 'open',
      roundNumber: 2,
      autoAdvance: true,
      cancellationPolicy: 'requeue',
      createdAt: now - 2 * day,
      updatedAt: now,
    });

    // ── Attendees ──────────────────────────────────────────

    await upsertDinnerAttendee(ctx, {
      dinnerEventId: upcomingDinner1,
      userId: aleckId,
      status: 'confirmed',
      confirmedAt: now - 5 * day,
    });
    await upsertDinnerAttendee(ctx, {
      dinnerEventId: upcomingDinner1,
      userId: marcusId,
      status: 'confirmed',
      confirmedAt: now - 4 * day,
    });
    await upsertDinnerAttendee(ctx, {
      dinnerEventId: upcomingDinner1,
      userId: daniId,
      status: 'confirmed',
      confirmedAt: now - 4 * day,
    });
    await upsertDinnerAttendee(ctx, {
      dinnerEventId: upcomingDinner1,
      userId: priyaId,
      status: 'confirmed',
      confirmedAt: now - 3 * day,
    });

    // ── Memories ───────────────────────────────────────────

    const pastDinner = await upsertDinnerEvent(ctx, {
      circleId: recCenterId,
      hostUserId: aleckId,
      title: 'February Rec Center Dinner',
      venue: 'Spoon & Stable',
      venueAddress: '211 N 1st St, Minneapolis, MN 55401',
      scheduledDate: now - 22 * day,
      groupSize: 8,
      spotsLeft: 0,
      status: 'completed',
      roundNumber: 2,
      autoAdvance: true,
      cancellationPolicy: 'skip_round',
      createdAt: now - 30 * day,
      updatedAt: now - 22 * day,
    });

    await upsertMemory(ctx, {
      circleId: recCenterId,
      dinnerEventId: pastDinner,
      uploadedByUserId: aleckId,
      photoUrl: 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      caption: 'Valentine\'s dinner at Spoon & Stable',
      takenAt: now - 22 * day,
      createdAt: now - 22 * day,
    });
    await upsertMemory(ctx, {
      circleId: recCenterId,
      dinnerEventId: pastDinner,
      uploadedByUserId: daniId,
      photoUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      takenAt: now - 22 * day,
      createdAt: now - 22 * day,
    });
    await upsertMemory(ctx, {
      circleId: recCenterId,
      uploadedByUserId: marcusId,
      photoUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      takenAt: now - 37 * day,
      createdAt: now - 37 * day,
    });

    // ── Notifications ──────────────────────────────────────

    await upsertNotification(ctx, {
      userId: aleckId,
      title: 'You\'re both confirmed!',
      body: 'You and your dinner partner are confirmed for March Rec Center Dinner.',
      notificationType: 'match_confirmed',
      isRead: false,
      createdAt: now - 2 * hour,
    });
    await upsertNotification(ctx, {
      userId: aleckId,
      title: 'New join request',
      body: 'Someone wants to join Rec Center Ballers.',
      notificationType: 'join_request',
      isRead: false,
      createdAt: now - 6 * hour,
    });

    return {
      success: true,
      mode: 'upserted',
      demoViewerUserId,
      users: { aleckId, marcusId, daniId, priyaId, jordanId },
      circles: { recCenterId, mplsFoodiesId, fridayBookId },
      dinners: { upcomingDinner1, openDinner1, openDinner2, openDinner3, pastDinner },
    };
  },
});

type SeedUserInput = {
  clerkId: string;
  firstName: string;
  lastName: string;
  username: string;
  email: string;
  city: string;
  flakeScore: number;
  dinnersAttended: number;
  dinnersInvited: number;
  unreadNotificationsCount: number;
  invitesSentCount: number;
  hasJoinedCircle: boolean;
  availabilityDates: string[];
  interests: string[];
  createdAt: number;
  updatedAt: number;
  bio?: string;
  occupation?: string;
  lat?: number;
  lng?: number;
};

type SeedCircleInput = {
  ownerUserId?: string;
  name: string;
  vibe: string;
  city: string;
  visibility: 'public' | 'private';
  pairingFrequency: 'weekly' | 'biweekly' | 'monthly';
  maxDinnerSize: number;
  adminUserId: any;
  inviteCode: string;
  hashtags: string[];
  createdAt: number;
  updatedAt: number;
};

type SeedMembershipInput = {
  circleId: any;
  userId: any;
  role: 'owner' | 'admin' | 'member';
  status: 'active' | 'pending' | 'blocked';
  joinedAt: number;
};

type SeedDinnerInput = {
  circleId: any;
  hostUserId: any;
  title: string;
  venue?: string;
  venueAddress?: string;
  venueLat?: number;
  venueLng?: number;
  scheduledDate: number;
  groupSize: number;
  spotsLeft: number;
  status: 'draft' | 'open' | 'paired' | 'confirmed' | 'completed' | 'cancelled';
  roundNumber: number;
  autoAdvance: boolean;
  cancellationPolicy: 'skip_round' | 'requeue';
  createdAt: number;
  updatedAt: number;
};

type SeedAttendeeInput = {
  dinnerEventId: any;
  userId: any;
  status: 'invited' | 'confirmed' | 'declined' | 'attended' | 'no_show';
  confirmedAt?: number;
  attendedAt?: number;
};

type SeedMemoryInput = {
  circleId: any;
  dinnerEventId?: any;
  uploadedByUserId: any;
  photoUrl: string;
  caption?: string;
  takenAt: number;
  createdAt: number;
};

type SeedNotificationInput = {
  userId: any;
  title: string;
  body: string;
  notificationType: string;
  isRead: boolean;
  createdAt: number;
  sourceId?: string;
  data?: unknown;
};

async function upsertDemoViewerUser(ctx: any, payload: SeedUserInput) {
  const existingDemoUser = await findUserByClerkId(ctx, demoViewerUserId);
  const legacyDemoUser = existingDemoUser
    ? null
    : await findUserByClerkId(ctx, legacyDemoViewerUserId);
  const targetUser = existingDemoUser ?? legacyDemoUser;

  if (targetUser) {
    await ctx.db.patch(targetUser._id, {
      ...payload,
      clerkId: demoViewerUserId,
      createdAt: targetUser.createdAt,
      updatedAt: payload.updatedAt,
    });
    return targetUser._id;
  }

  return await ctx.db.insert('users', payload);
}

async function upsertUser(ctx: any, payload: SeedUserInput) {
  const existingUser = await findUserByClerkId(ctx, payload.clerkId);
  if (existingUser) {
    await ctx.db.patch(existingUser._id, {
      ...payload,
      createdAt: existingUser.createdAt,
      updatedAt: payload.updatedAt,
    });
    return existingUser._id;
  }

  return await ctx.db.insert('users', payload);
}

async function upsertCircle(ctx: any, payload: SeedCircleInput) {
  const existingCircle = await ctx.db
    .query('circles')
    .withIndex('by_invite_code', (q: any) => q.eq('inviteCode', payload.inviteCode))
    .first();
  if (existingCircle) {
    await ctx.db.patch(existingCircle._id, {
      ...payload,
      createdAt: existingCircle.createdAt,
      updatedAt: payload.updatedAt,
    });
    return existingCircle._id;
  }

  return await ctx.db.insert('circles', payload);
}

async function upsertCircleMembership(ctx: any, payload: SeedMembershipInput) {
  const existingMembership = await ctx.db
    .query('circleMemberships')
    .withIndex('by_circle_and_user', (q: any) =>
      q.eq('circleId', payload.circleId).eq('userId', payload.userId),
    )
    .first();
  if (existingMembership) {
    await ctx.db.patch(existingMembership._id, payload);
    return existingMembership._id;
  }

  return await ctx.db.insert('circleMemberships', payload);
}

async function upsertDinnerEvent(ctx: any, payload: SeedDinnerInput) {
  const existingDinner = await findDinnerByTitle(ctx, payload.circleId, payload.title);
  if (existingDinner) {
    await ctx.db.patch(existingDinner._id, {
      ...payload,
      createdAt: existingDinner.createdAt,
      updatedAt: payload.updatedAt,
    });
    return existingDinner._id;
  }

  return await ctx.db.insert('dinnerEvents', payload);
}

async function upsertDinnerAttendee(ctx: any, payload: SeedAttendeeInput) {
  const existingAttendee = await ctx.db
    .query('dinnerAttendees')
    .withIndex('by_dinner_and_user', (q: any) =>
      q.eq('dinnerEventId', payload.dinnerEventId).eq('userId', payload.userId),
    )
    .first();
  if (existingAttendee) {
    await ctx.db.patch(existingAttendee._id, payload);
    return existingAttendee._id;
  }

  return await ctx.db.insert('dinnerAttendees', payload);
}

async function upsertMemory(ctx: any, payload: SeedMemoryInput) {
  const memories = await ctx.db
    .query('memories')
    .withIndex('by_circle', (q: any) => q.eq('circleId', payload.circleId))
    .collect();
  const existingMemory = memories.find(
    (memory: any) =>
      `${memory.uploadedByUserId}` === `${payload.uploadedByUserId}`
      && memory.photoUrl === payload.photoUrl
      && `${memory.dinnerEventId ?? ''}` === `${payload.dinnerEventId ?? ''}`,
  );
  if (existingMemory) {
    await ctx.db.patch(existingMemory._id, {
      ...payload,
      createdAt: existingMemory.createdAt,
    });
    return existingMemory._id;
  }

  return await ctx.db.insert('memories', payload);
}

async function upsertNotification(ctx: any, payload: SeedNotificationInput) {
  const notifications = await ctx.db
    .query('notifications')
    .withIndex('by_user', (q: any) => q.eq('userId', payload.userId))
    .collect();
  const existingNotification = notifications.find(
    (notification: any) =>
      notification.title === payload.title
      && notification.body === payload.body
      && notification.notificationType === payload.notificationType,
  );
  if (existingNotification) {
    await ctx.db.patch(existingNotification._id, {
      ...payload,
      createdAt: existingNotification.createdAt,
    });
    return existingNotification._id;
  }

  return await ctx.db.insert('notifications', payload);
}

async function findUserByClerkId(ctx: any, clerkId: string) {
  return await ctx.db
    .query('users')
    .withIndex('by_clerk_id', (q: any) => q.eq('clerkId', clerkId))
    .first();
}

async function findDinnerByTitle(ctx: any, circleId: any, title: string) {
  const dinners = await ctx.db
    .query('dinnerEvents')
    .withIndex('by_circle', (q: any) => q.eq('circleId', circleId))
    .collect();
  return dinners.find((dinner: any) => dinner.title === title);
}