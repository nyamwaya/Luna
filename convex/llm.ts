import { action } from './_generated/server';
import { api } from './_generated/api';
import { v } from 'convex/values';

/// Calls an LLM provider and stores an assistant response.
export const generateAssistantReply = action({
  args: {
    conversationKey: v.string(),
    userText: v.string(),
  },
  handler: async (ctx, args) => {
    console.log('llm:generateAssistantReply:start', {
      conversationKey: args.conversationKey,
      userText: args.userText,
    });

    const history = await ctx.runQuery(api.messages.listByConversation, {
      conversationKey: args.conversationKey,
    });

    console.log('llm:generateAssistantReply:history', {
      conversationKey: args.conversationKey,
      historyCount: history.length,
    });

    const assistantText = await generateReplyFromProvider(history, args.userText);

    console.log('llm:generateAssistantReply:assistantText', {
      conversationKey: args.conversationKey,
      assistantText,
    });

    await ctx.runMutation(api.messages.sendAssistantMessage, {
      conversationKey: args.conversationKey,
      text: assistantText,
      metadata: {
        provider: resolveProviderName(),
      },
    });

    return { text: assistantText };
  },
});

async function generateReplyFromProvider(
  history: Array<{ author: string; text: string }>,
  userText: string,
): Promise<string> {
  const apiKey = process.env.OPENROUTER_API_KEY ?? process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return `I heard you: "${userText}". Add OPENROUTER_API_KEY (or OPENAI_API_KEY) in Convex env to enable live LLM replies.`;
  }

  const isOpenRouter = Boolean(process.env.OPENROUTER_API_KEY);
  const endpoint = process.env.LLM_BASE_URL ??
    (isOpenRouter
      ? 'https://openrouter.ai/api/v1/chat/completions'
      : 'https://api.openai.com/v1/chat/completions');
  const model = process.env.LLM_MODEL ?? (isOpenRouter ? 'openai/gpt-4o-mini' : 'gpt-4o-mini');

  console.log('llm:provider', {
    provider: isOpenRouter ? 'openrouter' : 'openai',
    endpoint,
    model,
  });

  const messages = [
    {
      role: 'system',
      content:
        'You are Luma, a concise, warm dinner-coordination assistant. Keep replies short and actionable.',
    },
    ...history.map((item) => ({
      role: item.author === 'user' ? 'user' : 'assistant',
      content: item.text,
    })),
    {
      role: 'user',
      content: userText,
    },
  ];

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      ...(isOpenRouter
        ? {
            'HTTP-Referer': process.env.OPENROUTER_SITE_URL ?? 'https://luma.mobile.app',
            'X-Title': process.env.OPENROUTER_APP_NAME ?? 'Luma Mobile',
          }
        : {}),
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: 0.5,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.log('llm:provider:error', {
      status: response.status,
      body: errorBody.slice(0, 400),
    });
    return `I could not reach the LLM provider yet (${response.status}). ${errorBody.slice(0, 200)}`;
  }

  const payload = (await response.json()) as {
    choices?: Array<{ message?: { content?: string } }>;
  };

  const reply = payload.choices?.[0]?.message?.content?.trim();
  if (!reply) {
    return 'I received an empty LLM response. Please try again.';
  }

  return reply;
}

function resolveProviderName(): string {
  if (process.env.OPENROUTER_API_KEY) {
    return 'openrouter';
  }

  if (process.env.OPENAI_API_KEY) {
    return 'openai';
  }

  return 'fallback';
}
