import { defineSchema, defineTable } from 'convex/server';
import { v } from 'convex/values';

export default defineSchema({

  users: defineTable({
    clerkId: v.string(),         // or whatever auth provider
    firstName: v.string(),
    lastName: v.string(),
    username: v.string(),
    email: v.string(),
    phoneNumber: v.optional(v.string()),
    bio: v.optional(v.string()),
    occupation: v.optional(v.string()),
    profilePhotoUrl: v.optional(v.string()),
    city: v.string(),
    lat: v.optional(v.number()),
    lng: v.optional(v.number()),
    fcmToken: v.optional(v.string()),
    flakeScore: v.number(),          // 0-100, lower is better
    dinnersAttended: v.number(),
    dinnersInvited: v.number(),
    unreadNotificationsCount: v.number(),
    invitesSentCount: v.number(),
    hasJoinedCircle: v.boolean(),
    availabilityDates: v.array(v.string()),  // ISO date strings
    interests: v.array(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_clerk_id', ['clerkId'])
    .index('by_city', ['city']),

  conversations: defineTable({
    key: v.string(),
    userId: v.optional(v.string()),
    title: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_key', ['key']),

  circles: defineTable({
    ownerUserId: v.optional(v.string()),
    name: v.string(),
    vibe: v.string(),
    city: v.string(),
    visibility: v.union(v.literal('public'), v.literal('private')),
    pairingFrequency: v.union(
      v.literal('weekly'),
      v.literal('biweekly'),
      v.literal('monthly')
    ),
    maxDinnerSize: v.number(),
    adminUserId: v.id('users'),
    inviteCode: v.string(),
    hashtags: v.array(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_city', ['city'])
    .index('by_invite_code', ['inviteCode'])
    .index('by_admin', ['adminUserId']),

  circleMemberships: defineTable({
    circleId: v.id('circles'),
    userId: v.id('users'),
    role: v.union(
      v.literal('owner'),
      v.literal('admin'),
      v.literal('member')
    ),
    status: v.union(
      v.literal('active'),
      v.literal('pending'),
      v.literal('blocked')
    ),
    joinedAt: v.number(),
  }).index('by_circle', ['circleId'])
    .index('by_user', ['userId'])
    .index('by_circle_and_user', ['circleId', 'userId']),

  dinnerEvents: defineTable({
    circleId: v.id('circles'),
    hostUserId: v.id('users'),
    title: v.string(),
    vibe: v.optional(v.string()),
    venue: v.optional(v.string()),
    venueAddress: v.optional(v.string()),
    venueLat: v.optional(v.number()),
    venueLng: v.optional(v.number()),
    scheduledDate: v.number(),           // unix timestamp
    groupSize: v.number(),
    spotsLeft: v.number(),
    status: v.union(
      v.literal('draft'),
      v.literal('open'),
      v.literal('paired'),
      v.literal('confirmed'),
      v.literal('completed'),
      v.literal('cancelled')
    ),
    roundNumber: v.number(),
    reportingDeadline: v.optional(v.number()),
    autoAdvance: v.boolean(),
    cancellationPolicy: v.union(
      v.literal('skip_round'),
      v.literal('requeue')
    ),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_circle', ['circleId'])
    .index('by_status', ['status'])
    .index('by_host', ['hostUserId']),

  dinnerAttendees: defineTable({
    dinnerEventId: v.id('dinnerEvents'),
    userId: v.id('users'),
    status: v.union(
      v.literal('invited'),
      v.literal('confirmed'),
      v.literal('declined'),
      v.literal('attended'),
      v.literal('no_show')
    ),
    confirmedAt: v.optional(v.number()),
    attendedAt: v.optional(v.number()),
  }).index('by_dinner', ['dinnerEventId'])
    .index('by_user', ['userId'])
    .index('by_dinner_and_user', ['dinnerEventId', 'userId']),

  dinnerMatches: defineTable({
    dinnerEventId: v.id('dinnerEvents'),
    status: v.union(
      v.literal('pending'),
      v.literal('revealed'),
      v.literal('confirmed'),
      v.literal('completed'),
      v.literal('expired'),
      v.literal('cancelled')
    ),
    revealAt: v.optional(v.number()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_dinner', ['dinnerEventId']),

  dinnerMatchGuests: defineTable({
    matchId: v.id('dinnerMatches'),
    userId: v.id('users'),
    confirmed: v.boolean(),
    attended: v.optional(v.boolean()),
    reportedAt: v.optional(v.number()),
    confirmedAt: v.optional(v.number()),
  }).index('by_match', ['matchId'])
    .index('by_user', ['userId']),

  memories: defineTable({
    circleId: v.id('circles'),
    dinnerEventId: v.optional(v.id('dinnerEvents')),
    uploadedByUserId: v.id('users'),
    photoUrl: v.string(),
    caption: v.optional(v.string()),
    takenAt: v.number(),
    createdAt: v.number(),
  }).index('by_circle', ['circleId'])
    .index('by_dinner', ['dinnerEventId']),

  notifications: defineTable({
    userId: v.id('users'),
    title: v.string(),
    body: v.string(),
    notificationType: v.string(),
    sourceId: v.optional(v.string()),
    isRead: v.boolean(),
    data: v.optional(v.any()),
    createdAt: v.number(),
  }).index('by_user', ['userId'])
    .index('by_user_unread', ['userId', 'isRead']),

  messages: defineTable({
    conversationKey: v.string(),
    author: v.union(v.literal('user'), v.literal('assistant'), v.literal('luma')),
    text: v.string(),
    metadata: v.optional(v.any()),
    createdAt: v.number(),
  }).index('by_conversation', ['conversationKey'])
    .index('by_conversation_created_at', ['conversationKey', 'createdAt']),

});