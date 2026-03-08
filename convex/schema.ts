import { defineSchema, defineTable } from 'convex/server';
import { v } from 'convex/values';

/// Convex schema for minimal realtime conversation + LLM flow.
export default defineSchema({
  conversations: defineTable({
    key: v.string(),
    title: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index('by_key', ['key']),

  messages: defineTable({
    conversationKey: v.string(),
    author: v.string(),
    text: v.string(),
    metadata: v.optional(v.any()),
    createdAt: v.number(),
  }).index('by_conversation_created_at', ['conversationKey', 'createdAt']),
});
