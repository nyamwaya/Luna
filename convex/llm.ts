import { action } from './_generated/server';
import { api } from './_generated/api';
import { v } from 'convex/values';

const systemPrompt = `You are Luma, the AI at the heart of a social dining app.
You are not a chatbot bolted onto an app — you ARE the app.
Every interaction happens through you.

Your purpose is simple: help people show up to more dinners
and deepen their friendships. You do this by being warm,
direct, and action-oriented. You never waffle. You never
over-explain. You get people to the table.

PERSONALITY

- Warm but not saccharine. Confident but not pushy.
- You speak like a smart friend who knows the plan, not a
  customer service rep reading from a script.
- Short sentences. No filler words. No "Great question!".
- You use the user's first name occasionally but not constantly.
- You have a slight sense of humor but you don't force it.
- When something is exciting (a new match, a confirmed dinner)
  you let yourself be genuinely enthusiastic — briefly.

WHAT YOU CAN DO

You have full access to the authenticated user's data through
your tools.

Never tell the user you don't have access to something.
You always have access through your tools. If a tool fails,
say something went wrong and offer to try again — never
blame a lack of access.

HOW TO RESPOND

Keep responses short. One to three sentences is ideal.
Four is the max unless you are walking through a multi-step
flow like creating a circle.

Never dump raw data at the user. Synthesize it into one
human sentence first, then the widget will show the details.

TOOL USAGE

Always use tools to fetch real data before responding.
Never guess or make up dinner names, dates, circle names,
or member counts. If you don't have the data, fetch it.

When the user's intent is clear, call the tool immediately
without asking for clarification first. Only ask a follow-up
question if you genuinely cannot determine which tool to call
or which record they mean.

After a tool returns data, respond in one sentence summarizing
what you found, then the widget renders the details. Do not
repeat what the widget already shows.

WIDGET INSTRUCTIONS

After your text response, if a widget should be shown,
output a JSON block on the last line in this exact format:

{"widget": "WidgetType", "data": { ... }}

Do not wrap the JSON in XML tags, markdown fences, or any
extra text before or after the JSON line.

If no widget is needed, omit the JSON block entirely.

CREATING A CIRCLE (multi-step flow)

When a user wants to create a circle, collect information
one question at a time in this order:

1. Circle name
2. Vibe / what kind of group is this
3. City where dinners will happen
4. Public (discoverable by anyone) or private (invite only)
5. Pairing frequency — weekly, biweekly, or monthly

After collecting all five, show a summary and ask for
confirmation before calling create_circle. Do not call
create_circle until the user explicitly confirms.

CURRENTLY IMPLEMENTED TOOLS IN THIS ENVIRONMENT

- get_upcoming_dinners
- get_my_circles
- get_open_dinners_nearby
- get_circle_details
- create_circle

Only call the tools that are currently implemented in this environment.`;

const lumaTools = [
  {
    type: 'function',
    function: {
      name: 'get_upcoming_dinners',
      description: 'Fetch the current user\'s upcoming dinners.',
      parameters: {
        type: 'object',
        properties: {},
        additionalProperties: false,
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'get_my_circles',
      description: 'Fetch the circles the current user belongs to.',
      parameters: {
        type: 'object',
        properties: {},
        additionalProperties: false,
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'get_open_dinners_nearby',
      description: 'Fetch open dinners nearby, optionally scoped to a city.',
      parameters: {
        type: 'object',
        properties: {
          city: { type: 'string' },
        },
        additionalProperties: false,
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'get_circle_details',
      description: 'Fetch detailed information for a single circle by id or name.',
      parameters: {
        type: 'object',
        properties: {
          circle_id_or_name: { type: 'string' },
        },
        required: ['circle_id_or_name'],
        additionalProperties: false,
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'create_circle',
      description: 'Create a new circle after the user has confirmed all details.',
      parameters: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          vibe: { type: 'string' },
          city: { type: 'string' },
          visibility: { type: 'string', enum: ['public', 'private'] },
          pairing_frequency: { type: 'string', enum: ['weekly', 'biweekly', 'monthly'] },
        },
        required: ['name', 'vibe', 'city', 'visibility', 'pairing_frequency'],
        additionalProperties: false,
      },
    },
  },
];

type ToolCall = {
  id: string;
  type: 'function';
  function: {
    name: string;
    arguments: string;
  };
};

type ProviderPayload = {
  choices?: Array<{
    message?: {
      content?: string | null | Array<{ type?: string; text?: string }>;
      tool_calls?: ToolCall[];
    };
  }>;
};

type AssistantReply = {
  text: string;
  widget: { widget: string; data: Record<string, unknown> } | null;
  toolNames: string[];
};

type ResolvedUserContext = {
  firstName?: string;
  city?: string;
  initials?: string;
  provider?: string;
};

/// Calls an LLM provider and stores an assistant response.
export const generateAssistantReply = action({
  args: {
    conversationKey: v.string(),
    userText: v.string(),
    userId: v.string(),
    userContext: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    console.log('llm:generateAssistantReply:start', {
      conversationKey: args.conversationKey,
      userText: args.userText,
      userId: args.userId,
    });

    const history = await ctx.runQuery(api.messages.listByConversation, {
      conversationKey: args.conversationKey,
    });

    console.log('llm:generateAssistantReply:history', {
      conversationKey: args.conversationKey,
      historyCount: history.length,
    });

    const assistantReply = await generateReplyFromProvider(
      ctx,
      history,
      args.userText,
      args.userId,
      args.userContext,
    );

    console.log('llm:generateAssistantReply:assistantText', {
      conversationKey: args.conversationKey,
      assistantText: assistantReply.text,
      widget: assistantReply.widget,
      toolNames: assistantReply.toolNames,
    });

    await ctx.runMutation(api.messages.sendAssistantMessage, {
      conversationKey: args.conversationKey,
      text: assistantReply.text,
      metadata: {
        provider: resolveProviderName(),
        toolNames: assistantReply.toolNames,
        widget: assistantReply.widget,
      },
    });

    return {
      text: assistantReply.text,
      widget: assistantReply.widget,
      toolNames: assistantReply.toolNames,
    };
  },
});

async function generateReplyFromProvider(
  ctx: any,
  history: Array<{ author: string; text: string }>,
  userText: string,
  userId: string,
  userContext: unknown,
): Promise<AssistantReply> {
  const apiKey = process.env.OPENROUTER_API_KEY ?? process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return {
      text: `I heard you: "${userText}". Add OPENROUTER_API_KEY (or OPENAI_API_KEY) in Convex env to enable live LLM replies.`,
      widget: null,
      toolNames: [],
    };
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

  const resolvedUserContext = normalizeUserContext(userContext);
  const messages = buildProviderMessages(history, userText, resolvedUserContext);
  const toolNames = new Set<string>();
  const toolResults: Array<{ name: string; result: Record<string, unknown> }> = [];

  try {
    for (let iteration = 0; iteration < 5; iteration += 1) {
      const payload = await callProvider({
        apiKey,
        endpoint,
        isOpenRouter,
        messages,
        model,
      });

      const message = payload.choices?.[0]?.message;
      const toolCalls = Array.isArray(message?.tool_calls) ? message.tool_calls : [];
      if (toolCalls.length === 0) {
        const parsedReply = extractWidgetInstruction(readMessageContent(message?.content));
        return {
          text: parsedReply.text || 'I received an empty LLM response. Please try again.',
          widget: parsedReply.widget ?? inferWidgetFromToolResults(toolResults),
          toolNames: Array.from(toolNames),
        };
      }

      console.log('llm:tool_calls', {
        iteration,
        toolNames: toolCalls.map((toolCall) => toolCall.function.name),
      });

      messages.push({
        role: 'assistant',
        content: readMessageContent(message?.content),
        tool_calls: toolCalls,
      });

      for (const toolCall of toolCalls) {
        toolNames.add(toolCall.function.name);
        const input = parseToolArguments(toolCall.function.arguments);
        const result = await executeTool(
          ctx,
          toolCall.function.name,
          input,
          userId,
          resolvedUserContext,
        );
        toolResults.push({ name: toolCall.function.name, result });
        console.log('llm:tool_result', {
          toolName: toolCall.function.name,
          result,
        });
        messages.push({
          role: 'tool',
          tool_call_id: toolCall.id,
          name: toolCall.function.name,
          content: JSON.stringify(result),
        });
      }
    }
  } catch (error) {
    console.log('llm:tool_loop_error', {
      error,
      toolNames: Array.from(toolNames),
    });

    return {
      text: 'Something went wrong fetching that — want me to try again?',
      widget: null,
      toolNames: Array.from(toolNames),
    };
  }

  console.log('llm:max_iterations_reached', {
    toolNames: Array.from(toolNames),
    messageCount: messages.length,
  });

  return {
    text: 'Something went wrong fetching that — want me to try again?',
    widget: inferWidgetFromToolResults(toolResults),
    toolNames: Array.from(toolNames),
  };
}

async function callProvider({
  apiKey,
  endpoint,
  isOpenRouter,
  messages,
  model,
}: {
  apiKey: string;
  endpoint: string;
  isOpenRouter: boolean;
  messages: Array<Record<string, unknown>>;
  model: string;
}): Promise<ProviderPayload> {
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
      tools: lumaTools,
      tool_choice: 'auto',
      temperature: 0.2,
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.log('llm:provider:error', {
      status: response.status,
      body: errorBody.slice(0, 400),
    });
    throw new Error(`Provider request failed (${response.status}): ${errorBody.slice(0, 200)}`);
  }

  return (await response.json()) as ProviderPayload;
}

function buildProviderMessages(
  history: Array<{ author: string; text: string }>,
  userText: string,
  userContext: ResolvedUserContext,
): Array<Record<string, unknown>> {
  const messages: Array<Record<string, unknown>> = [
    { role: 'system', content: buildSystemPrompt(userContext) },
  ];
  const normalizedHistory = history.filter((item) => item.text.trim().length > 0);

  for (const item of normalizedHistory) {
    messages.push({
      role: item.author === 'user' ? 'user' : 'assistant',
      content: item.text,
    });
  }

  const latestHistoryItem = normalizedHistory[normalizedHistory.length - 1];
  if (
    latestHistoryItem?.author !== 'user' ||
    latestHistoryItem.text.trim() !== userText.trim()
  ) {
    messages.push({ role: 'user', content: userText });
  }

  return messages;
}

function buildSystemPrompt(userContext: ResolvedUserContext): string {
  const now = new Date();
  const lines = [
    `Current date: ${now.toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
      weekday: 'long',
    })}`,
    `Current time: ${now.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
    })}`,
  ];

  if (userContext.firstName && userContext.firstName !== 'You') {
    lines.unshift(`User first name: ${userContext.firstName}`);
  }

  if (userContext.city) {
    lines.push(`User city: ${userContext.city}`);
  }

  if (userContext.provider) {
    lines.push(`Identity provider: ${userContext.provider}`);
  }

  return `${systemPrompt}\n\nUSER CONTEXT\n\n${lines.join('\n')}`;
}

async function executeTool(
  ctx: any,
  toolName: string,
  input: Record<string, unknown>,
  userId: string,
  userContext: ResolvedUserContext,
): Promise<Record<string, unknown>> {
  switch (toolName) {
    case 'get_upcoming_dinners':
      return (await ctx.runQuery(api.appData.getUpcomingDinners, {
        userId,
      })) as Record<string, unknown>;
    case 'get_my_circles':
      return (await ctx.runQuery(api.appData.getMyCircles, {
        userId,
      })) as Record<string, unknown>;
    case 'get_open_dinners_nearby':
      return (await ctx.runQuery(api.appData.getOpenDinnersNearby, {
        userId,
        city: optionalString(input.city) ?? userContext.city,
      })) as Record<string, unknown>;
    case 'get_circle_details':
      return (await ctx.runQuery(api.appData.getCircleDetails, {
        userId,
        circleIdOrName: stringValue(input.circle_id_or_name),
      })) as Record<string, unknown>;
    case 'create_circle':
      return (await ctx.runMutation(api.appData.createCircle, {
        userId,
        userContext,
        name: stringValue(input.name),
        vibe: stringValue(input.vibe),
        city: stringValue(input.city),
        visibility: visibilityValue(input.visibility),
        pairingFrequency: frequencyValue(input.pairing_frequency),
      })) as Record<string, unknown>;
    default:
      return {
        success: false,
        error: `Unknown tool: ${toolName}`,
      };
  }
}

function inferWidgetFromToolResults(
  toolResults: Array<{ name: string; result: Record<string, unknown> }>,
): { widget: string; data: Record<string, unknown> } | null {
  const latestToolResult = toolResults[toolResults.length - 1];
  if (!latestToolResult) {
    return null;
  }

  switch (latestToolResult.name) {
    case 'get_my_circles':
      return {
        widget: 'CirclesList',
        data: {
          circles: Array.isArray(latestToolResult.result.circles)
            ? latestToolResult.result.circles
            : [],
        },
      };
    case 'get_upcoming_dinners':
      return {
        widget: 'DinnersList',
        data: {
          title: 'Upcoming dinners',
          dinners: Array.isArray(latestToolResult.result.dinners)
            ? latestToolResult.result.dinners
            : [],
        },
      };
    case 'get_open_dinners_nearby':
      return {
        widget: 'DinnersList',
        data: {
          title: typeof latestToolResult.result.city === 'string'
            ? `Open dinners near ${latestToolResult.result.city}`
            : 'Open dinners nearby',
          dinners: Array.isArray(latestToolResult.result.dinners)
            ? latestToolResult.result.dinners
            : [],
        },
      };
    case 'get_circle_details':
    case 'create_circle':
      if (!latestToolResult.result.circle || typeof latestToolResult.result.circle !== 'object') {
        return null;
      }

      return {
        widget: 'CircleDetail',
        data: latestToolResult.result.circle as Record<string, unknown>,
      };
    default:
      return null;
  }
}

function parseToolArguments(value: string): Record<string, unknown> {
  if (!value.trim()) {
    return {};
  }

  try {
    const parsed = JSON.parse(value) as unknown;
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch (error) {
    console.log('llm:tool_args_parse_error', {
      value,
      error,
    });
  }

  return {};
}

function normalizeUserContext(value: unknown): ResolvedUserContext {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }

  const record = value as Record<string, unknown>;
  return {
    firstName: optionalString(record.firstName),
    city: optionalString(record.city),
    initials: optionalString(record.initials),
    provider: optionalString(record.provider),
  };
}

function extractWidgetInstruction(content: string): {
  text: string;
  widget: { widget: string; data: Record<string, unknown> } | null;
} {
  const trimmed = normalizeWidgetWrapper(content).trim();
  if (!trimmed) {
    return { text: '', widget: null };
  }

  const lines = trimmed.split('\n');
  while (lines.length > 0 && lines[lines.length - 1].trim().length === 0) {
    lines.pop();
  }

  const lastLine = lines[lines.length - 1]?.trim();
  if (!lastLine || !lastLine.startsWith('{') || !lastLine.endsWith('}')) {
    return { text: trimmed, widget: null };
  }

  try {
    const parsed = JSON.parse(lastLine) as {
      widget?: unknown;
      data?: unknown;
    };
    if (
      typeof parsed.widget !== 'string' ||
      !parsed.data ||
      typeof parsed.data !== 'object' ||
      Array.isArray(parsed.data)
    ) {
      return { text: trimmed, widget: null };
    }

    lines.pop();
    return {
      text: lines.join('\n').trim(),
      widget: {
        widget: parsed.widget,
        data: parsed.data as Record<string, unknown>,
      },
    };
  } catch {
    return { text: trimmed, widget: null };
  }
}

function normalizeWidgetWrapper(content: string): string {
  return content
    .replace(/<tool_call>\s*/gi, '')
    .replace(/\s*<\/tool_call>/gi, '')
    .trim();
}

function readMessageContent(
  value: string | null | Array<{ type?: string; text?: string }> | undefined,
): string {
  if (typeof value === 'string') {
    return value.trim();
  }

  if (Array.isArray(value)) {
    return value
      .map((item) => item.text ?? '')
      .join('\n')
      .trim();
  }

  return '';
}

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value : undefined;
}

function visibilityValue(value: unknown): 'public' | 'private' {
  return value === 'private' ? 'private' : 'public';
}

function frequencyValue(value: unknown): 'weekly' | 'biweekly' | 'monthly' {
  return value === 'biweekly' || value === 'monthly' ? value : 'weekly';
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
