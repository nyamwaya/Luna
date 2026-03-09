import { mutation, query } from './_generated/server';
import { v } from 'convex/values';

const demoViewerUserId = 'local-demo-user';
const defaultCity = 'Minneapolis';

export const getUpcomingDinners = query({
  args: {
    userId: v.string(),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId);
    const dinners = await loadUpcomingDinnerSummaries(ctx, scope);

    return {
      success: true,
      dinners,
      count: dinners.length,
      userId: scope.effectiveUserId,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
    };
  },
});

export const getMyCircles = query({
  args: {
    userId: v.string(),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId);
    const circles = await loadCircleSummaries(ctx, scope);

    return {
      success: true,
      circles,
      count: circles.length,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
    };
  },
});

export const getColdStartSnapshot = query({
  args: {
    userId: v.string(),
    userContext: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId, args.userContext);
    const circles = await loadCircleSummaries(ctx, scope);
    const upcomingDinners = (await loadUpcomingDinnerSummaries(ctx, scope)).filter(
      (dinner: DinnerSummary) => dinner.status === 'confirmed',
    );
    const pendingInvites = await loadPendingInviteSummaries(ctx, scope);
    const openDinnersNearby = await loadOpenDinnerSummaries(ctx, scope.city);
    const createdAt = typeof scope.user?.createdAt === 'number' ? scope.user.createdAt : Date.now();

    return {
      success: true,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
      snapshot: {
        user: {
          id: `${scope.user?._id ?? args.userId}`,
          firstName: scope.user?.firstName ?? 'Friend',
          city: scope.city,
          hasJoinedCircle: Boolean(scope.user?.hasJoinedCircle),
          daysSinceCreated: Math.max(0, Math.floor((Date.now() - createdAt) / dayMs)),
        },
        circles,
        upcomingDinners,
        pendingInvites,
        openDinnersNearby,
      },
    };
  },
});

export const getHomeDashboard = query({
  args: {
    userId: v.string(),
    userContext: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId, args.userContext);
    const circles = await loadCircleSummaries(ctx, scope);
    const openDinners = await loadOpenDinnerSummaries(ctx, scope.city);
    const upcomingDinners = await loadUpcomingDinnerSummaries(ctx, scope);
    const confirmedDinner = await loadNextConfirmedDinnerSummary(ctx, scope);

    return {
      success: true,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
      view: {
        city: scope.city,
        user_initials: scope.initials,
        quick_actions_prompt: 'What do you want to do?',
        open_seats_prompt: openDinners.length > 0
          ? `${openDinners.length} dinners near you still have open seats this week.`
          : 'No open dinners near you right now.',
        open_seats: openDinners.map((dinner) => ({
          id: dinner.id,
          title: dinner.title,
          subtitle: `${dinner.dateLabel} · ${dinner.timeLabel}`,
          seats_left: dinner.seatsLeft,
          is_hot: dinner.seatsLeft <= 2,
        })),
        active_circle_count: circles.length,
        circles: circles.map((circle) => ({
          id: circle.id,
          name: circle.name,
          city: circle.city,
          vibe: circle.vibe,
          member_count: circle.memberCount,
          pairing_frequency: circle.pairingFrequency,
          invite_code: circle.inviteCode,
          next_pairing_label: circle.nextPairingLabel,
        })),
        upcoming_dinners: upcomingDinners.map((dinner) => ({
          id: dinner.id,
          title: dinner.title,
          circle_name: dinner.circleName,
          venue: dinner.venue,
          city: dinner.city,
          date_label: dinner.dateLabel,
          time_label: dinner.timeLabel,
          status: dinner.status,
          seats_left: dinner.seatsLeft,
        })),
        confirmed_dinner: confirmedDinner
          ? {
              badge: `${confirmedDinner.circleName.toUpperCase()} · ✓ CONFIRMED`,
              date_label: confirmedDinner.dateLabel,
              time_label: confirmedDinner.timeLabel,
              venue: confirmedDinner.venue,
              city: confirmedDinner.city,
            }
          : null,
      },
    };
  },
});

export const getOpenDinnersNearby = query({
  args: {
    userId: v.string(),
    city: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId);
    const city = optionalString(args.city) ?? scope.city;
    const dinners = await loadOpenDinnerSummaries(ctx, city);

    return {
      success: true,
      dinners,
      count: dinners.length,
      city,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
    };
  },
});

export const getCircleDetails = query({
  args: {
    userId: v.string(),
    circleIdOrName: v.string(),
  },
  handler: async (ctx, args) => {
    const scope = await resolveViewerScope(ctx, args.userId);
    const circle = await findCircleByIdOrName(ctx, args.circleIdOrName);
    if (!circle) {
      return {
        success: false,
        found: false,
        error: `No circle found for ${args.circleIdOrName}.`,
      };
    }
    const detail = await buildCircleDetail(ctx, circle);

    return {
      success: true,
      found: true,
      circle: detail,
      dataMode: scope.isDemoFallback ? 'demo' : 'user',
    };
  },
});

export const createCircle = mutation({
  args: {
    userId: v.string(),
    userContext: v.optional(v.any()),
    name: v.string(),
    vibe: v.string(),
    city: v.string(),
    visibility: v.union(v.literal('public'), v.literal('private')),
    pairingFrequency: v.union(
      v.literal('weekly'),
      v.literal('biweekly'),
      v.literal('monthly'),
    ),
  },
  handler: async (ctx, args) => {
    const name = requiredNonEmpty(args.name);
    const vibe = requiredNonEmpty(args.vibe);
    const city = requiredNonEmpty(args.city);
    if (!name || !vibe || !city) {
      return {
        success: false,
        error: 'Circle name, vibe, and city are all required before creating a circle.',
      };
    }

    const localUser = await ensureLocalUserRecord(ctx, args.userId, args.userContext);
    const inviteCode = buildInviteCode(name);
    const now = Date.now();
    const circleId = await ctx.db.insert('circles', {
      ownerUserId: args.userId,
      name,
      vibe,
      city,
      visibility: args.visibility,
      pairingFrequency: args.pairingFrequency,
      maxDinnerSize: 8,
      adminUserId: localUser._id,
      inviteCode,
      hashtags: buildHashtags(name, vibe),
      createdAt: now,
      updatedAt: now,
    });

    await ctx.db.insert('circleMemberships', {
      circleId,
      userId: localUser._id,
      role: 'owner',
      status: 'active',
      joinedAt: now,
    });

    await ctx.db.patch(localUser._id, {
      hasJoinedCircle: true,
      updatedAt: now,
    });

    return {
      success: true,
      circle: {
        id: circleId,
        name,
        city,
        vibe,
        memberCount: 1,
        pairingFrequency: args.pairingFrequency,
        visibility: args.visibility,
        inviteCode,
        nextPairingLabel: 'First dinner coming soon',
      },
    };
  },
});

export const ensureLocalUser = mutation({
  args: {
    userId: v.string(),
    userContext: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    const user = await ensureLocalUserRecord(ctx, args.userId, args.userContext);
    return {
      success: true,
      user: {
        id: user._id,
        userId: args.userId,
        firstName: user.firstName,
        city: user.city,
      },
    };
  },
});

type PairingFrequency = 'weekly' | 'biweekly' | 'monthly';
type CircleVisibility = 'public' | 'private';
type DinnerStatus = 'draft' | 'open' | 'paired' | 'confirmed' | 'completed' | 'cancelled';
const dayMs = 24 * 60 * 60 * 1000;

type ViewerScope = {
  effectiveUserId: string;
  user: any | null;
  city: string;
  initials: string;
  isDemoFallback: boolean;
};

type CircleSummary = {
  id: string;
  name: string;
  city: string;
  vibe: string;
  memberCount: number;
  pairingFrequency: PairingFrequency;
  visibility: CircleVisibility;
  inviteCode: string;
  nextPairingLabel: string;
};

type DinnerSummary = {
  id: string;
  title: string;
  circleName: string;
  venue: string;
  city: string;
  dateLabel: string;
  timeLabel: string;
  status: DinnerStatus;
  seatsLeft: number;
};

type CircleDetailPayload = CircleSummary & {
  members: Array<{ id: string; firstName: string }>;
  upcomingDinners: DinnerSummary[];
  memories: Array<{ id: string; caption: string }>;
};

async function resolveViewerScope(
  ctx: any,
  requestedUserId: string,
  userContext?: unknown,
): Promise<ViewerScope> {
  const profile = normalizeUserContext(userContext);
  const requestedUser = await findUserByExternalId(ctx, requestedUserId);
  const requestedUserHasMemberships = requestedUser
    ? await hasActiveMemberships(ctx, requestedUser._id)
    : false;

  let effectiveUser = requestedUser ?? null;
  let isDemoFallback = false;

  if ((!effectiveUser || !requestedUserHasMemberships) && requestedUserId !== demoViewerUserId) {
    const demoUser = await findUserByExternalId(ctx, demoViewerUserId);
    if (demoUser) {
      effectiveUser = demoUser;
      isDemoFallback = true;
    }
  }

  const identityUser = requestedUser ?? effectiveUser;
  return {
    effectiveUserId: isDemoFallback ? demoViewerUserId : requestedUserId,
    user: effectiveUser,
    city: profile.city ?? identityUser?.city ?? defaultCity,
    initials: profile.initials
      ?? buildInitials(profile.firstName ?? identityUser?.firstName ?? ''),
    isDemoFallback,
  };
}

async function loadCircleSummaries(ctx: any, scope: ViewerScope): Promise<CircleSummary[]> {
  if (!scope.user) {
    return [];
  }

  const memberships = await loadActiveMembershipsForUser(ctx, scope.user._id);
  if (memberships.length === 0) {
    return [];
  }

  const circleMap = await loadCircleMap(
    ctx,
    memberships.map((membership: any) => membership.circleId),
  );
  const summaries = await Promise.all(
    Array.from(circleMap.values()).map(
      async (circle: any) => await buildCircleSummary(ctx, circle),
    ),
  );

  return summaries.sort((left: CircleSummary, right: CircleSummary) =>
    left.name.localeCompare(right.name),
  );
}

async function loadUpcomingDinnerSummaries(
  ctx: any,
  scope: ViewerScope,
): Promise<DinnerSummary[]> {
  if (!scope.user) {
    return [];
  }

  const memberships = await loadActiveMembershipsForUser(ctx, scope.user._id);
  const circleIds = memberships.map((membership: any) => membership.circleId);
  if (circleIds.length === 0) {
    return [];
  }

  const circleMap = await loadCircleMap(ctx, circleIds);
  const dinners = await loadDinnerEventsForCircleIds(ctx, circleIds);

  return dinners
    .filter((dinner: any) => isUpcomingDinner(dinner))
    .sort(compareByScheduledDate)
    .map((dinner: any) => {
      const circle = circleMap.get(`${dinner.circleId}`);
      return circle ? mapDinnerSummary(dinner, circle) : null;
    })
    .filter(isDefined);
}

async function loadOpenDinnerSummaries(
  ctx: any,
  city: string,
): Promise<DinnerSummary[]> {
  const normalizedCity = normalize(city);
  const dinners = await ctx.db
    .query('dinnerEvents')
    .withIndex('by_status', (q: any) => q.eq('status', 'open'))
    .collect();
  const futureOpenDinners = dinners.filter(
    (dinner: any) => dinner.spotsLeft > 0 && isUpcomingDinner(dinner),
  );
  const circleMap = await loadCircleMap(
    ctx,
    futureOpenDinners.map((dinner: any) => dinner.circleId),
  );

  return futureOpenDinners
    .map((dinner: any) => {
      const circle = circleMap.get(`${dinner.circleId}`);
      if (!circle || !normalize(circle.city).includes(normalizedCity)) {
        return null;
      }

      return mapDinnerSummary(dinner, circle);
    })
    .filter(isDefined)
    .sort((left: DinnerSummary, right: DinnerSummary) =>
      left.dateLabel.localeCompare(right.dateLabel),
    );
}

async function loadPendingInviteSummaries(
  ctx: any,
  scope: ViewerScope,
): Promise<DinnerSummary[]> {
  if (!scope.user) {
    return [];
  }

  const attendees = await ctx.db
    .query('dinnerAttendees')
    .withIndex('by_user', (q: any) => q.eq('userId', scope.user._id))
    .collect();
  const dinners = (
    await Promise.all(
      attendees
        .filter((attendee: any) => attendee.status === 'invited')
        .map(async (attendee: any) => await ctx.db.get(attendee.dinnerEventId)),
    )
  )
    .filter(isDefined)
    .filter((dinner: any) => isUpcomingDinner(dinner))
    .sort(compareByScheduledDate);
  const summaries = await Promise.all(
    dinners.map(async (dinner: any) => {
      const circle = await ctx.db.get(dinner.circleId);
      return circle ? mapDinnerSummary(dinner, circle) : null;
    }),
  );

  return summaries.filter(isDefined);
}

async function loadNextConfirmedDinnerSummary(
  ctx: any,
  scope: ViewerScope,
): Promise<DinnerSummary | null> {
  if (!scope.user) {
    return null;
  }

  const attendees = await ctx.db
    .query('dinnerAttendees')
    .withIndex('by_user', (q: any) => q.eq('userId', scope.user._id))
    .collect();
  const dinners = (
    await Promise.all(
      attendees
        .filter((attendee: any) => attendee.status === 'confirmed')
        .map(async (attendee: any) => await ctx.db.get(attendee.dinnerEventId)),
    )
  )
    .filter(isDefined)
    .filter((dinner: any) => isConfirmedUpcomingDinner(dinner))
    .sort(compareByScheduledDate);
  const dinner = dinners[0];
  if (!dinner) {
    return null;
  }

  const circle = await ctx.db.get(dinner.circleId);
  return circle ? mapDinnerSummary(dinner, circle) : null;
}

async function findCircleByIdOrName(ctx: any, circleIdOrName: string) {
  const needle = normalize(circleIdOrName);
  const circles = await ctx.db.query('circles').collect();
  return circles.find(
    (circle: any) =>
      normalize(`${circle._id}`) === needle
      || normalize(circle.name) === needle
      || normalize(circle.inviteCode) === needle,
  );
}

async function buildCircleDetail(
  ctx: any,
  circle: any,
): Promise<CircleDetailPayload> {
  const summary = await buildCircleSummary(ctx, circle);
  const memberships = await loadActiveMembershipsForCircle(ctx, circle._id);
  const members = (
    await Promise.all(
      memberships.map(async (membership: any) => {
        const user = await ctx.db.get(membership.userId);
        if (!user) {
          return null;
        }

        return {
          id: `${membership.userId}`,
          firstName: user.firstName || 'Member',
        };
      }),
    )
  ).filter(isDefined);
  const memories = await ctx.db
    .query('memories')
    .withIndex('by_circle', (q: any) => q.eq('circleId', circle._id))
    .collect();
  const upcomingDinners = (await loadDinnerEventsForCircleIds(ctx, [circle._id]))
    .filter((dinner: any) => isUpcomingDinner(dinner))
    .sort(compareByScheduledDate)
    .slice(0, 3)
    .map((dinner: any) => mapDinnerSummary(dinner, circle));

  return {
    ...summary,
    members: members.length > 0
      ? members
      : [{ id: 'user-you', firstName: 'You' }],
    upcomingDinners,
    memories: memories
      .slice()
      .sort((left: any, right: any) => right.createdAt - left.createdAt)
      .slice(0, 3)
      .map((memory: any) => ({
        id: `${memory._id}`,
        caption: memory.caption ?? '',
      })),
  };
}

async function buildCircleSummary(
  ctx: any,
  circle: any,
): Promise<CircleSummary> {
  const memberships = await loadActiveMembershipsForCircle(ctx, circle._id);
  const nextDinner = (await loadDinnerEventsForCircleIds(ctx, [circle._id]))
    .filter((dinner: any) => isUpcomingDinner(dinner))
    .sort(compareByScheduledDate)[0];

  return {
    id: `${circle._id}`,
    name: optionalString(circle.name) ?? optionalString(circle.inviteCode) ?? 'Circle',
    city: optionalString(circle.city) ?? '',
    vibe: optionalString(circle.vibe) ?? '',
    memberCount: Math.max(memberships.length, 1),
    pairingFrequency: circle.pairingFrequency,
    visibility: circle.visibility,
    inviteCode: circle.inviteCode,
    nextPairingLabel: buildNextPairingLabel(nextDinner),
  };
}

async function loadCircleMap(ctx: any, circleIds: any[]): Promise<Map<string, any>> {
  const uniqueCircleIds = uniqueValuesByString(circleIds);
  const circles = await Promise.all(
    uniqueCircleIds.map(async (circleId: any) => await ctx.db.get(circleId)),
  );
  const circleMap = new Map<string, any>();

  for (const circle of circles) {
    if (circle) {
      circleMap.set(`${circle._id}`, circle);
    }
  }

  return circleMap;
}

async function loadDinnerEventsForCircleIds(
  ctx: any,
  circleIds: any[],
): Promise<any[]> {
  const uniqueCircleIds = uniqueValuesByString(circleIds);
  const dinnerGroups = await Promise.all(
    uniqueCircleIds.map(
      async (circleId: any) =>
        await ctx.db
          .query('dinnerEvents')
          .withIndex('by_circle', (q: any) => q.eq('circleId', circleId))
          .collect(),
    ),
  );

  return dinnerGroups.reduce((all: any[], group: any[]) => all.concat(group), []);
}

async function loadActiveMembershipsForUser(ctx: any, userId: any): Promise<any[]> {
  const memberships = await ctx.db
    .query('circleMemberships')
    .withIndex('by_user', (q: any) => q.eq('userId', userId))
    .collect();
  return memberships.filter((membership: any) => membership.status === 'active');
}

async function loadActiveMembershipsForCircle(ctx: any, circleId: any): Promise<any[]> {
  const memberships = await ctx.db
    .query('circleMemberships')
    .withIndex('by_circle', (q: any) => q.eq('circleId', circleId))
    .collect();
  return memberships.filter((membership: any) => membership.status === 'active');
}

async function hasActiveMemberships(ctx: any, userId: any): Promise<boolean> {
  const memberships = await loadActiveMembershipsForUser(ctx, userId);
  return memberships.length > 0;
}

function mapDinnerSummary(dinner: any, circle: any): DinnerSummary {
  return {
    id: `${dinner._id}`,
    title: dinner.title || `${circle.name} dinner`,
    circleName: circle.name,
    venue: dinner.venue ?? 'TBD',
    city: circle.city,
    dateLabel: formatDateLabel(dinner.scheduledDate),
    timeLabel: formatTimeLabel(dinner.scheduledDate),
    status: dinner.status,
    seatsLeft: dinner.spotsLeft ?? 0,
  };
}

function buildNextPairingLabel(dinner: any | undefined): string {
  if (!dinner) {
    return 'First dinner coming soon';
  }

  return `Next dinner · ${formatDateLabel(dinner.scheduledDate)}`;
}

function compareByScheduledDate(left: any, right: any): number {
  return left.scheduledDate - right.scheduledDate;
}

function isUpcomingDinner(dinner: any): boolean {
  return dinner.scheduledDate >= Date.now()
    && dinner.status !== 'draft'
    && dinner.status !== 'completed'
    && dinner.status !== 'cancelled';
}

function isConfirmedUpcomingDinner(dinner: any): boolean {
  return dinner.status === 'confirmed' && dinner.scheduledDate >= Date.now();
}

function formatDateLabel(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'short',
    day: 'numeric',
  });
}

function formatTimeLabel(timestamp: number): string {
  return new Date(timestamp).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });
}

function uniqueValuesByString<T>(values: T[]): T[] {
  const valueMap = new Map<string, T>();
  for (const value of values) {
    valueMap.set(`${value}`, value);
  }

  return Array.from(valueMap.values());
}

function isDefined<T>(value: T | null | undefined): value is T {
  return value !== null && value !== undefined;
}

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

function requiredNonEmpty(value: string): string | null {
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function buildInviteCode(name: string): string {
  const base = name.replace(/[^a-zA-Z0-9]/g, '').toUpperCase().slice(0, 6);
  const suffix = Date.now().toString().slice(-4);
  return `${base || 'CIRCLE'}${suffix}`;
}

function buildHashtags(name: string, vibe: string): string[] {
  return `${name} ${vibe}`
    .split(/[^a-zA-Z0-9]+/)
    .map((value) => value.trim().toLowerCase())
    .filter((value, index, values) => value.length > 2 && values.indexOf(value) === index)
    .slice(0, 4);
}

function normalizeUserContext(value: unknown): {
  firstName?: string;
  city?: string;
  initials?: string;
} {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }

  const record = value as Record<string, unknown>;
  return {
    firstName: optionalString(record.firstName),
    city: optionalString(record.city),
    initials: optionalString(record.initials),
  };
}

async function findUserByExternalId(ctx: any, userId: string) {
  return await ctx.db
    .query('users')
    .withIndex('by_clerk_id', (q: any) => q.eq('clerkId', userId))
    .first();
}

async function ensureLocalUserRecord(ctx: any, userId: string, userContext: unknown) {
  const now = Date.now();
  const profile = normalizeUserContext(userContext);
  const existingUser = await findUserByExternalId(ctx, userId);

  if (existingUser) {
    await ctx.db.patch(existingUser._id, {
      firstName: profile.firstName ?? existingUser.firstName,
      city: profile.city ?? existingUser.city,
      updatedAt: now,
    });

    return {
      ...existingUser,
      firstName: profile.firstName ?? existingUser.firstName,
      city: profile.city ?? existingUser.city,
    };
  }

  const firstName = profile.firstName ?? 'Friend';
  const city = profile.city ?? defaultCity;
  const username = buildUsername(userId);
  const insertedId = await ctx.db.insert('users', {
    clerkId: userId,
    firstName,
    lastName: '',
    username,
    email: `${username}@local.luma`,
    city,
    flakeScore: 0,
    dinnersAttended: 0,
    dinnersInvited: 0,
    unreadNotificationsCount: 0,
    invitesSentCount: 0,
    hasJoinedCircle: false,
    availabilityDates: [],
    interests: [],
    createdAt: now,
    updatedAt: now,
  });

  const createdUser = await ctx.db.get(insertedId);
  if (!createdUser) {
    throw new Error(`Failed to create local user for ${userId}`);
  }

  return createdUser;
}

function buildUsername(userId: string): string {
  const normalized = userId.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
  return normalized.length > 0 ? normalized.slice(0, 24) : `local${Date.now().toString().slice(-6)}`;
}

function buildInitials(firstName: string): string {
  const normalized = firstName.trim();
  if (normalized.length === 0) {
    return 'ME';
  }

  const parts = normalized
    .split(/\s+/)
    .filter((value: string) => value.length > 0);
  if (parts.length === 0) {
    return 'ME';
  }

  if (parts.length === 1) {
    const word = parts[0].toUpperCase();
    return word.length >= 2 ? word.slice(0, 2) : word;
  }

  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined;
}
