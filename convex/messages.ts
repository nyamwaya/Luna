import { mutation, query } from './_generated/server';
import { v } from 'convex/values';

/// Ensures the default conversation exists for a given key.
export const ensureDefaultConversation = mutation({
  args: {
    conversationKey: v.string(),
    title: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    console.log('messages:ensureDefaultConversation:start', {
      conversationKey: args.conversationKey,
      hasTitle: Boolean(args.title),
    });

    const existingConversation = await ctx.db
      .query('conversations')
      .withIndex('by_key', (q) => q.eq('key', args.conversationKey))
      .first();

    if (existingConversation) {
      await ctx.db.patch(existingConversation._id, {
        updatedAt: now,
      });
      console.log('messages:ensureDefaultConversation:existing', {
        conversationKey: args.conversationKey,
      });
      return { conversationKey: args.conversationKey };
    }

    await ctx.db.insert('conversations', {
      key: args.conversationKey,
      title: args.title,
      createdAt: now,
      updatedAt: now,
    });

    console.log('messages:ensureDefaultConversation:created', {
      conversationKey: args.conversationKey,
    });

    return { conversationKey: args.conversationKey };
  },
});

/// Returns conversation messages in ascending chronological order.
export const listByConversation = query({
  args: {
    conversationKey: v.string(),
  },
  handler: async (ctx, args) => {
    console.log('messages:listByConversation:start', {
      conversationKey: args.conversationKey,
    });

    const messages = await ctx.db
      .query('messages')
      .withIndex('by_conversation_created_at', (q) =>
        q.eq('conversationKey', args.conversationKey),
      )
      .collect();

    const sortedMessages = messages.sort((a, b) => a.createdAt - b.createdAt);
    console.log('messages:listByConversation:result', {
      conversationKey: args.conversationKey,
      count: sortedMessages.length,
      latestAuthor: sortedMessages[sortedMessages.length - 1]?.author,
      latestText: sortedMessages[sortedMessages.length - 1]?.text,
    });

    return sortedMessages;
  },
});

/// Persists a user-authored message.
export const sendUserMessage = mutation({
  args: {
    conversationKey: v.string(),
    text: v.string(),
    metadata: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    console.log('messages:sendUserMessage:start', {
      conversationKey: args.conversationKey,
      text: args.text,
    });

    await ctx.db.insert('messages', {
      conversationKey: args.conversationKey,
      author: 'user',
      text: args.text,
      metadata: args.metadata,
      createdAt: Date.now(),
    });

    console.log('messages:sendUserMessage:done', {
      conversationKey: args.conversationKey,
    });
  },
});

/// Persists an assistant-authored message.
export const sendAssistantMessage = mutation({
  args: {
    conversationKey: v.string(),
    text: v.string(),
    metadata: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    console.log('messages:sendAssistantMessage:start', {
      conversationKey: args.conversationKey,
      text: args.text,
      provider: (args.metadata as { provider?: string } | undefined)?.provider,
    });

    await ctx.db.insert('messages', {
      conversationKey: args.conversationKey,
      author: 'luma',
      text: args.text,
      metadata: args.metadata,
      createdAt: Date.now(),
    });

    console.log('messages:sendAssistantMessage:done', {
      conversationKey: args.conversationKey,
    });
  },
});
