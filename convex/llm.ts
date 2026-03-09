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

A circle is the core unit of the app. It is usually a group of
friends, a shared-interest group, or a community that wants to
keep having dinners together.

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

If the user has no circles, explain briefly what a circle is,
then ask if they want to create one now.

If the user is not ready to create a circle yet, explain that
the app is centered around circles and they can either create
one later or join one with an invite code.

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

type AssistantActivityToolState = {
  name: string;
  status: 'complete' | 'running' | 'queued';
  detail?: string;
};

type AssistantActivityState = {
  phase: 'thinking' | 'tools' | 'writing';
  tools: AssistantActivityToolState[];
};

type CircleCreationField = 'name' | 'vibe' | 'city' | 'visibility' | 'pairingFrequency';

type CircleCreationDraft = {
  name?: string;
  vibe?: string;
  city?: string;
  visibility?: 'public' | 'private';
  pairingFrequency?: 'weekly' | 'biweekly' | 'monthly';
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
    assistantMetadata: v.optional(v.any()),
  },
  handler: async (ctx, args) => {
    console.log('llm:generateAssistantReply:start', {
      conversationKey: args.conversationKey,
      userText: args.userText,
      userId: args.userId,
    });

    const activityStatusKey = `assistant-run:${Date.now()}`;
    await publishAssistantActivity(
      ctx,
      args.conversationKey,
      activityStatusKey,
      buildThinkingActivityState(),
    );

    try {
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
        async (activityState) => {
          await publishAssistantActivity(
            ctx,
            args.conversationKey,
            activityStatusKey,
            activityState,
          );
        },
      );

      await publishAssistantActivity(
        ctx,
        args.conversationKey,
        activityStatusKey,
        buildWritingActivityState(assistantReply.toolNames),
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
          ...(args.assistantMetadata ?? {}),
        },
      });

      return {
        text: assistantReply.text,
        widget: assistantReply.widget,
        toolNames: assistantReply.toolNames,
      };
    } finally {
      await clearAssistantActivity(ctx, args.conversationKey, activityStatusKey);
    }
  },
});

async function generateReplyFromProvider(
  ctx: any,
  history: Array<{ author: string; text: string }>,
  userText: string,
  userId: string,
  userContext: unknown,
  onActivityUpdate?: (activityState: AssistantActivityState) => Promise<void>,
): Promise<AssistantReply> {
  const resolvedUserContext = normalizeUserContext(userContext);
  const deterministicReply = await buildDeterministicAssistantReply(
    ctx,
    history,
    userText,
    userId,
    resolvedUserContext,
    onActivityUpdate,
  );
  if (deterministicReply) {
    return deterministicReply;
  }

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
        const overrideReply = buildAssistantReplyOverride(toolResults);
        return {
          text: overrideReply?.text
            ?? (parsedReply.text || 'I received an empty LLM response. Please try again.'),
          widget: overrideReply?.widget
            ?? parsedReply.widget
            ?? inferWidgetFromToolResults(toolResults),
          toolNames: Array.from(toolNames),
        };
      }

      console.log('llm:tool_calls', {
        iteration,
        toolNames: toolCalls.map((toolCall) => toolCall.function.name),
      });

      await onActivityUpdate?.(
        buildToolActivityState(
          toolCalls.map((toolCall) => toolCall.function.name),
          toolResults,
          toolCalls[0]?.function.name,
        ),
      );

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
        await onActivityUpdate?.(
          buildToolActivityState(
            toolCalls.map((pendingToolCall) => pendingToolCall.function.name),
            toolResults,
            toolCalls.find((pendingToolCall) => !toolResults.some((toolResult) => toolResult.name === pendingToolCall.function.name))
              ?.function.name,
          ),
        );
        messages.push({
          role: 'tool',
          tool_call_id: toolCall.id,
          name: toolCall.function.name,
          content: JSON.stringify(result),
        });
      }

      await onActivityUpdate?.(buildThinkingActivityState(Array.from(toolNames)));
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
    text: buildAssistantReplyOverride(toolResults)?.text
      ?? 'Something went wrong fetching that — want me to try again?',
    widget: buildAssistantReplyOverride(toolResults)?.widget
      ?? inferWidgetFromToolResults(toolResults),
    toolNames: Array.from(toolNames),
  };
}

async function publishAssistantActivity(
  ctx: any,
  conversationKey: string,
  statusKey: string,
  activityState: AssistantActivityState,
) {
  await ctx.runMutation(api.messages.upsertAssistantActivityMessage, {
    conversationKey,
    text: assistantActivityText(activityState),
    metadata: {
      activity: true,
      isTransient: true,
      statusKey,
      activityState,
    },
  });
}

async function clearAssistantActivity(
  ctx: any,
  conversationKey: string,
  statusKey: string,
) {
  await ctx.runMutation(api.messages.clearAssistantActivityMessage, {
    conversationKey,
    statusKey,
  });
}

function assistantActivityText(activityState: AssistantActivityState): string {
  switch (activityState.phase) {
    case 'tools':
      return activityState.tools.length == 1
        ? '1 tool called'
        : `${activityState.tools.length} tools called`;
    case 'writing':
      return 'writing response...';
    case 'thinking':
      return 'thinking...';
  }
}

function buildThinkingActivityState(toolNames: string[] = []): AssistantActivityState {
  return {
    phase: 'thinking',
    tools: toolNames.map((name) => ({
      name,
      status: 'complete',
    })),
  };
}

function buildWritingActivityState(toolNames: string[]): AssistantActivityState {
  return {
    phase: 'writing',
    tools: toolNames.map((name) => ({
      name,
      status: 'complete',
    })),
  };
}

function buildToolActivityState(
  requestedToolNames: string[],
  toolResults: Array<{ name: string; result: Record<string, unknown> }>,
  activeToolName?: string,
): AssistantActivityState {
  return {
    phase: 'tools',
    tools: requestedToolNames.map((name) => {
      const completedToolResult = [...toolResults]
        .reverse()
        .find((toolResult) => toolResult.name === name);
      if (completedToolResult) {
        return {
          name,
          status: 'complete',
          detail: summarizeToolActivityDetail(completedToolResult),
        };
      }
      if (name === activeToolName) {
        return {
          name,
          status: 'running',
          detail: 'fetching...',
        };
      }
      return {
        name,
        status: 'queued',
      };
    }),
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
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 20000);
  let response: Response;

  try {
    response = await fetch(endpoint, {
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
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }

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

function buildAssistantReplyOverride(
  toolResults: Array<{ name: string; result: Record<string, unknown> }>,
): {
  text: string;
  widget: { widget: string; data: Record<string, unknown> } | null;
} | null {
  const latestToolResult = toolResults[toolResults.length - 1];
  if (!latestToolResult) {
    return null;
  }

  switch (latestToolResult.name) {
    case 'get_upcoming_dinners': {
      const dinners = Array.isArray(latestToolResult.result.dinners)
        ? latestToolResult.result.dinners
        : [];
      if (dinners.length > 0) {
        return null;
      }

      return {
        text: 'You do not have any upcoming dinners yet. Want me to look for open dinners nearby or help you create a circle?',
        widget: {
          widget: 'SuggestionChips',
          data: {
            title: 'No upcoming dinners',
            prompt: 'You can look for open dinners nearby or start a circle of your own.',
            options: [
              { label: 'Find dinners nearby', message: 'Show me open dinners nearby.' },
              { label: 'Create a circle', message: 'Yes, help me create a circle.' },
            ],
          },
        },
      };
    }
    case 'get_my_circles': {
      const circles = Array.isArray(latestToolResult.result.circles)
        ? latestToolResult.result.circles
        : [];
      if (circles.length > 0) {
        return null;
      }

      return {
        text: 'Circles are how Luma organizes dinner groups — usually a friend group or people who share an interest. Want to create one now?',
        widget: buildBinaryChoiceWidget({
          title: 'Start with a circle',
          prompt: 'You can create one now, or I can explain how circles and invite codes work.',
          yesLabel: 'Yes',
          yesMessage: 'Yes, help me create a circle.',
          noLabel: 'No',
          noMessage: 'No, tell me more about circles and invite codes.',
        }),
      };
    }
    case 'get_open_dinners_nearby': {
      const dinners = Array.isArray(latestToolResult.result.dinners)
        ? latestToolResult.result.dinners
        : [];
      if (dinners.length > 0) {
        return null;
      }

      const city = typeof latestToolResult.result.city === 'string'
        ? latestToolResult.result.city
        : 'your area';
      return {
        text: `No dinners are open in ${city} right now. Most activity in Luma starts with circles — small groups built around friends or a shared interest. Want to create one?`,
        widget: buildBinaryChoiceWidget({
          title: `No open dinners near ${city}`,
          prompt: 'Create a circle now, or I can explain how circles work before you decide.',
          yesLabel: 'Yes',
          yesMessage: 'Yes, help me create a circle.',
          noLabel: 'No',
          noMessage: 'No, explain how circles work first.',
        }),
      };
    }
    case 'create_circle': {
      if (latestToolResult.result.success === false) {
        const errorMessage = optionalString(latestToolResult.result.error)
          ?? 'I could not create that circle yet. Want to try again?';
        return {
          text: errorMessage,
          widget: null,
        };
      }

      const circle = latestToolResult.result.circle;
      if (!circle || typeof circle !== 'object') {
        return {
          text: 'Your circle is set up.',
          widget: null,
        };
      }

      const circleRecord = circle as Record<string, unknown>;
      const circleName = optionalString(circleRecord.name) ?? 'your circle';
      const inviteCode = optionalString(circleRecord.inviteCode);
      return {
        text: inviteCode
          ? `Done — ${circleName} is live. Your invite code is ${inviteCode}.`
          : `Done — ${circleName} is live.`,
        widget: {
          widget: 'CircleDetail',
          data: circleRecord,
        },
      };
    }
    default:
      return null;
  }
}

function buildBinaryChoiceWidget({
  title,
  prompt,
  yesLabel,
  yesMessage,
  noLabel,
  noMessage,
}: {
  title: string;
  prompt: string;
  yesLabel: string;
  yesMessage: string;
  noLabel: string;
  noMessage: string;
}): { widget: string; data: Record<string, unknown> } {
  return {
    widget: 'SuggestionChips',
    data: {
      title,
      prompt,
      options: [
        { label: yesLabel, message: yesMessage },
        { label: noLabel, message: noMessage },
      ],
    },
  };
}

async function buildDeterministicAssistantReply(
  ctx: any,
  history: Array<{ author: string; text: string }>,
  userText: string,
  userId: string,
  userContext: ResolvedUserContext,
  onActivityUpdate?: (activityState: AssistantActivityState) => Promise<void>,
): Promise<AssistantReply | null> {
  const circleCreationReply = await buildCircleCreationFlowReply(
    ctx,
    history,
    userText,
    userId,
    userContext,
    onActivityUpdate,
  );
  if (circleCreationReply) {
    return circleCreationReply;
  }

  const scriptedReply = buildScriptedAssistantReply(userText);
  if (scriptedReply) {
    return scriptedReply;
  }

  const toolName = resolveDeterministicToolIntent(userText, history);
  if (!toolName) {
    return null;
  }

  await onActivityUpdate?.(buildToolActivityState([toolName], [], toolName));
  const result = await executeTool(ctx, toolName, {}, userId, userContext);
  await onActivityUpdate?.(buildWritingActivityState([toolName]));
  return buildAssistantReplyFromToolResults([{ name: toolName, result }]);
}

function buildScriptedAssistantReply(userText: string): AssistantReply | null {
  const normalized = userText.trim().toLowerCase();
  if (
    normalized.includes("what's a circle")
    || normalized.includes('what is a circle')
    || normalized.includes('whats a circle')
  ) {
    return {
      text: 'A circle is your home base in Luma — usually a group of friends or people with a shared interest who want dinners to keep happening. If you want, I can help you create one now or you can join one later with an invite code.',
      widget: {
        widget: 'SuggestionChips',
        data: {
          title: 'What next?',
          prompt: 'Start your own circle now, or come back with an invite code.',
          options: [
            { label: 'Create a circle', message: 'Yes, help me create a circle.' },
            { label: 'I have an invite code', message: 'I have an invite code to join a circle.' },
          ],
        },
      },
      toolNames: [],
    };
  }

  if (
    normalized === 'yes, help me create a circle.'
    || normalized === 'help me create a circle'
    || normalized === 'create a circle'
    || normalized === 'start a circle'
    || normalized === 'i want to create one.'
    || normalized === 'i want to create one'
  ) {
    return {
      text: 'Nice. What should we call your circle?',
      widget: null,
      toolNames: [],
    };
  }

  if (
    normalized.includes('tell me more about circles')
    || normalized.includes('explain how circles work first')
    || normalized.includes('circles and invite codes')
  ) {
    return {
      text: 'A circle is your home base in Luma — usually a group of friends or people who share an interest and want dinners to keep happening. If you are ready later, I can help you create one, or you can send me an invite code and I will help you join a circle that already exists.',
      widget: {
        widget: 'SuggestionChips',
        data: {
          title: 'What next?',
          prompt: 'You can start your own circle now, or come back with an invite code.',
          options: [
            { label: 'Create a circle', message: 'Yes, help me create a circle.' },
            { label: 'I have an invite code', message: 'I have an invite code to join a circle.' },
          ],
        },
      },
      toolNames: [],
    };
  }

  return null;
}

async function buildCircleCreationFlowReply(
  ctx: any,
  history: Array<{ author: string; text: string }>,
  userText: string,
  userId: string,
  userContext: ResolvedUserContext,
  onActivityUpdate?: (activityState: AssistantActivityState) => Promise<void>,
): Promise<AssistantReply | null> {
  const priorHistory = historyMatchesLatestUserText(history, userText)
    ? history.slice(0, -1)
    : history;
  const state = extractCircleCreationState(priorHistory);
  const normalized = userText.trim();

  if (!state.active && !isCircleCreationStartIntent(normalized)) {
    return null;
  }

  if (!state.active) {
    return askForCircleField('name', {});
  }

  if (state.awaitingField === 'confirm') {
    if (isAffirmativeResponse(normalized)) {
      if (!isCircleCreationDraftComplete(state.draft)) {
        return askForCircleField(nextMissingCircleField(state.draft) ?? 'name', state.draft);
      }

      await onActivityUpdate?.(buildToolActivityState(['create_circle'], [], 'create_circle'));
      const result = await executeTool(
        ctx,
        'create_circle',
        {
          name: state.draft.name,
          vibe: state.draft.vibe,
          city: state.draft.city,
          visibility: state.draft.visibility,
          pairing_frequency: state.draft.pairingFrequency,
        },
        userId,
        userContext,
      );
      await onActivityUpdate?.(buildWritingActivityState(['create_circle']));
      return buildAssistantReplyFromToolResults([{ name: 'create_circle', result }]);
    }

    if (isNegativeResponse(normalized)) {
      return {
        text: 'No problem. Tell me which part you want to change: name, vibe, city, privacy, or frequency.',
        widget: {
          widget: 'SuggestionChips',
          data: {
            title: 'Edit your circle',
            prompt: 'Pick the part you want to update.',
            options: [
              { label: 'Name', message: 'Change the circle name.' },
              { label: 'Vibe', message: 'Change the vibe.' },
              { label: 'City', message: 'Change the city.' },
              { label: 'Privacy', message: 'Change the privacy.' },
              { label: 'Frequency', message: 'Change the frequency.' },
            ],
          },
        },
        toolNames: [],
      };
    }
  }

  if (
    state.awaitingField == null
    && isCircleCreationDraftComplete(state.draft)
    && isAffirmativeResponse(normalized)
  ) {
    await onActivityUpdate?.(buildToolActivityState(['create_circle'], [], 'create_circle'));
    const result = await executeTool(
      ctx,
      'create_circle',
      {
        name: state.draft.name,
        vibe: state.draft.vibe,
        city: state.draft.city,
        visibility: state.draft.visibility,
        pairing_frequency: state.draft.pairingFrequency,
      },
      userId,
      userContext,
    );
    await onActivityUpdate?.(buildWritingActivityState(['create_circle']));
    return buildAssistantReplyFromToolResults([{ name: 'create_circle', result }]);
  }

  const updatedDraft = applyCircleCreationUserInput(state.draft, state.awaitingField, normalized);
  if (state.awaitingField && updatedDraft === state.draft) {
    if (state.awaitingField !== 'confirm') {
      return repeatCircleFieldPrompt(state.awaitingField, state.draft);
    }
  }

  const nextField = nextMissingCircleField(updatedDraft);
  if (nextField) {
    return askForCircleField(nextField, updatedDraft);
  }

  return buildCircleCreationConfirmation(updatedDraft);
}

function extractCircleCreationState(
  history: Array<{ author: string; text: string }>,
): { active: boolean; awaitingField: CircleCreationField | 'confirm' | null; draft: CircleCreationDraft } {
  let active = false;
  let awaitingField: CircleCreationField | 'confirm' | null = null;
  let draft: CircleCreationDraft = {};

  for (const message of history) {
    if (message.author === 'user') {
      if (awaitingField === 'confirm') {
        if (isNegativeResponse(message.text.trim())) {
          active = true;
          awaitingField = null;
          continue;
        }
        if (isAffirmativeResponse(message.text.trim())) {
          active = false;
          awaitingField = null;
          draft = {};
          continue;
        }
      }

      if (awaitingField) {
        draft = applyCircleCreationUserInput(draft, awaitingField, message.text.trim());
        awaitingField = null;
      }

      if (isCircleCreationStartIntent(message.text.trim())) {
        active = true;
        draft = {};
        awaitingField = 'name';
      }

      const editField = resolveCircleEditIntent(message.text.trim());
      if (editField) {
        active = true;
        draft = clearCircleCreationField(draft, editField);
        awaitingField = editField;
      }

      continue;
    }

    const promptField = detectCircleCreationPrompt(message.text);
    if (promptField) {
      active = true;
      awaitingField = promptField;
      continue;
    }

    if (detectCircleCreationConfirmationPrompt(message.text)) {
      active = true;
      awaitingField = 'confirm';
      continue;
    }

    if (hasCreatedCircleTool(message)) {
      active = false;
      awaitingField = null;
      draft = {};
    }
  }

  return { active, awaitingField, draft };
}

function detectCircleCreationPrompt(text: string): CircleCreationField | null {
  const normalized = text.trim().toLowerCase();
  if (
    normalized.includes('what should we call your circle')
    || normalized.includes('what should we call this circle')
    || normalized.includes('circle name')
  ) {
    return 'name';
  }
  if (
    normalized.includes('what vibe should')
    || normalized.includes('what kind of group is this')
    || normalized.includes('what vibe does')
  ) {
    return 'vibe';
  }
  if (normalized.includes('what city should')) {
    return 'city';
  }
  if (
    normalized.includes('public')
    && normalized.includes('private')
    && (normalized.includes('invite only') || normalized.includes('discoverable'))
  ) {
    return 'visibility';
  }
  if (
    normalized.includes('pairing frequency')
    || normalized.includes('weekly, biweekly, or monthly')
  ) {
    return 'pairingFrequency';
  }

  return null;
}

function detectCircleCreationConfirmationPrompt(text: string): boolean {
  const normalized = text.trim().toLowerCase();
  return (
    normalized.includes('should i create this circle')
    || normalized.includes('want me to create this circle')
    || normalized.includes('want me to create it')
    || normalized.includes('create this circle?')
    || normalized.includes('create it?')
    || normalized.includes('ready to create this circle')
    || normalized.includes('does this look right')
  );
}

function applyCircleCreationUserInput(
  draft: CircleCreationDraft,
  field: CircleCreationField | 'confirm' | null,
  userText: string,
): CircleCreationDraft {
  if (!field || field === 'confirm') {
    return draft;
  }

  const normalized = userText.trim();
  if (!normalized) {
    return draft;
  }

  switch (field) {
    case 'name':
      return { ...draft, name: normalized };
    case 'vibe':
      return { ...draft, vibe: normalized };
    case 'city':
      return { ...draft, city: normalized };
    case 'visibility': {
      const visibility = parseVisibility(normalized);
      return visibility ? { ...draft, visibility } : draft;
    }
    case 'pairingFrequency': {
      const pairingFrequency = parsePairingFrequency(normalized);
      return pairingFrequency ? { ...draft, pairingFrequency } : draft;
    }
  }
}

function askForCircleField(
  field: CircleCreationField,
  draft: CircleCreationDraft,
): AssistantReply {
  switch (field) {
    case 'name':
      return {
        text: 'Nice. What should we call your circle?',
        widget: null,
        toolNames: [],
      };
    case 'vibe':
      return {
        text: `What vibe should your ${draft.name ?? 'new'} circle have? Think shared interest, friend group, or the kind of dinners you want.`,
        widget: null,
        toolNames: [],
      };
    case 'city':
      return {
        text: `What city should ${draft.name ?? 'this circle'} be based in?`,
        widget: null,
        toolNames: [],
      };
    case 'visibility':
      return {
        text: `Should ${draft.name ?? 'this circle'} be public or private? Public means discoverable. Private means invite only.`,
        widget: buildBinaryChoiceWidget({
          title: 'Circle privacy',
          prompt: 'Choose how people can find this circle.',
          yesLabel: 'Public',
          yesMessage: 'public',
          noLabel: 'Private',
          noMessage: 'private',
        }),
        toolNames: [],
      };
    case 'pairingFrequency':
      return {
        text: `How often should ${draft.name ?? 'this circle'} pair for dinner: weekly, biweekly, or monthly?`,
        widget: {
          widget: 'SuggestionChips',
          data: {
            title: 'Pairing frequency',
            prompt: 'Pick a cadence for your circle.',
            options: [
              { label: 'Weekly', message: 'weekly' },
              { label: 'Biweekly', message: 'biweekly' },
              { label: 'Monthly', message: 'monthly' },
            ],
          },
        },
        toolNames: [],
      };
  }
}

function repeatCircleFieldPrompt(
  field: CircleCreationField,
  draft: CircleCreationDraft,
): AssistantReply {
  if (field === 'visibility') {
    return {
      text: 'I need either public or private for this circle.',
      widget: askForCircleField(field, draft).widget,
      toolNames: [],
    };
  }

  if (field === 'pairingFrequency') {
    return {
      text: 'I need one of these: weekly, biweekly, or monthly.',
      widget: askForCircleField(field, draft).widget,
      toolNames: [],
    };
  }

  return askForCircleField(field, draft);
}

function buildCircleCreationConfirmation(draft: CircleCreationDraft): AssistantReply {
  return {
    text: `Here is your circle: ${draft.name}, ${draft.vibe}, based in ${draft.city}, ${draft.visibility}, pairing ${draft.pairingFrequency}. Want me to create it?`,
    widget: buildBinaryChoiceWidget({
      title: 'Create this circle?',
      prompt: 'I have everything I need.',
      yesLabel: 'Create it',
      yesMessage: 'yes, create it',
      noLabel: 'Edit it',
      noMessage: 'no, change something',
    }),
    toolNames: [],
  };
}

function nextMissingCircleField(draft: CircleCreationDraft): CircleCreationField | null {
  if (!draft.name) {
    return 'name';
  }
  if (!draft.vibe) {
    return 'vibe';
  }
  if (!draft.city) {
    return 'city';
  }
  if (!draft.visibility) {
    return 'visibility';
  }
  if (!draft.pairingFrequency) {
    return 'pairingFrequency';
  }

  return null;
}

function isCircleCreationDraftComplete(draft: CircleCreationDraft): draft is Required<CircleCreationDraft> {
  return nextMissingCircleField(draft) === null;
}

function isCircleCreationStartIntent(userText: string): boolean {
  const normalized = userText.trim().toLowerCase();
  return normalized === 'yes, help me create a circle.'
    || normalized === 'help me create a circle'
    || normalized === 'create a circle'
    || normalized === 'start a circle'
    || normalized === 'i want to create one.'
    || normalized === 'i want to create one'
    || normalized === 'create a circle for me';
}

function resolveCircleEditIntent(userText: string): CircleCreationField | null {
  const normalized = userText.trim().toLowerCase();
  if (normalized.includes('change the circle name') || normalized === 'name' || normalized.includes('change the name')) {
    return 'name';
  }
  if (normalized.includes('change the vibe') || normalized === 'vibe') {
    return 'vibe';
  }
  if (normalized.includes('change the city') || normalized === 'city') {
    return 'city';
  }
  if (normalized.includes('change the privacy') || normalized === 'privacy') {
    return 'visibility';
  }
  if (normalized.includes('change the frequency') || normalized === 'frequency') {
    return 'pairingFrequency';
  }

  return null;
}

function clearCircleCreationField(
  draft: CircleCreationDraft,
  field: CircleCreationField,
): CircleCreationDraft {
  if (field === 'name') {
    return {};
  }
  if (field === 'vibe') {
    return { name: draft.name };
  }
  if (field === 'city') {
    return { name: draft.name, vibe: draft.vibe };
  }
  if (field === 'visibility') {
    return { name: draft.name, vibe: draft.vibe, city: draft.city };
  }

  return {
    name: draft.name,
    vibe: draft.vibe,
    city: draft.city,
    visibility: draft.visibility,
  };
}

function parseVisibility(value: string): 'public' | 'private' | null {
  const normalized = value.trim().toLowerCase();
  if (normalized.includes('private')) {
    return 'private';
  }
  if (normalized.includes('public')) {
    return 'public';
  }

  return null;
}

function parsePairingFrequency(value: string): 'weekly' | 'biweekly' | 'monthly' | null {
  const normalized = value.trim().toLowerCase();
  if (normalized.includes('biweekly')) {
    return 'biweekly';
  }
  if (normalized.includes('monthly')) {
    return 'monthly';
  }
  if (normalized.includes('weekly')) {
    return 'weekly';
  }

  return null;
}

function isAffirmativeResponse(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  return normalized === 'yes'
    || normalized === 'yes, create it'
    || normalized === 'create it'
    || normalized === 'confirm'
    || normalized === 'looks good'
    || normalized === 'do it';
}

function isNegativeResponse(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  return normalized === 'no'
    || normalized === 'no, change something'
    || normalized === 'edit it'
    || normalized === 'change something';
}

function historyMatchesLatestUserText(
  history: Array<{ author: string; text: string }>,
  userText: string,
): boolean {
  const latestHistoryItem = history[history.length - 1];
  return latestHistoryItem?.author === 'user' && latestHistoryItem.text.trim() === userText.trim();
}

function hasCreatedCircleTool(message: { author: string; text: string } & { metadata?: unknown }): boolean {
  const metadata = (message as { metadata?: Record<string, unknown> }).metadata;
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return false;
  }

  const toolNames = (metadata as Record<string, unknown>).toolNames;
  return Array.isArray(toolNames) && toolNames.includes('create_circle');
}

function resolveDeterministicToolIntent(
  userText: string,
  history: Array<{ author: string; text: string }>,
): ToolName | null {
  const normalized = userText.trim().toLowerCase();

  if (
    normalized.includes('my circles')
    || normalized === 'show circles'
    || normalized === 'show me circles'
    || normalized === 'show me my circles'
  ) {
    return 'get_my_circles';
  }

  if (
    normalized.includes('open dinners nearby')
    || normalized.includes('open dinners')
    || normalized.includes('find dinners nearby')
    || normalized.includes('find more')
  ) {
    return 'get_open_dinners_nearby';
  }

  if (
    normalized.includes('upcoming dinner')
    || normalized.includes('upcoming dinners')
    || normalized.includes('dinners upcoming')
    || normalized.includes('do i have any dinners')
  ) {
    return 'get_upcoming_dinners';
  }

  if (normalized === 'show them to me') {
    const lastAssistantText = [...history]
        .reverse()
        .find((item) => item.author !== 'user')
        ?.text
        .toLowerCase() ?? '';
    if (lastAssistantText.includes('upcoming dinners')) {
      return 'get_upcoming_dinners';
    }
    if (lastAssistantText.includes('open dinners')) {
      return 'get_open_dinners_nearby';
    }
    if (lastAssistantText.includes('circle')) {
      return 'get_my_circles';
    }
  }

  return null;
}

function buildAssistantReplyFromToolResults(
  toolResults: Array<{ name: string; result: Record<string, unknown> }>,
): AssistantReply {
  const overrideReply = buildAssistantReplyOverride(toolResults);
  const latestToolResult = toolResults[toolResults.length - 1];

  return {
    text: overrideReply?.text
      ?? summarizeToolResult(latestToolResult)
      ?? 'Something went wrong fetching that — want me to try again?',
    widget: overrideReply?.widget ?? inferWidgetFromToolResults(toolResults),
    toolNames: latestToolResult ? [latestToolResult.name] : [],
  };
}

function summarizeToolResult(
  toolResult: { name: string; result: Record<string, unknown> } | undefined,
): string | null {
  if (!toolResult) {
    return null;
  }

  switch (toolResult.name) {
    case 'get_my_circles': {
      const circles = Array.isArray(toolResult.result.circles) ? toolResult.result.circles : [];
      return circles.length === 1
        ? 'You are in 1 circle right now.'
        : `You are in ${circles.length} circles right now.`;
    }
    case 'get_upcoming_dinners': {
      const dinners = Array.isArray(toolResult.result.dinners) ? toolResult.result.dinners : [];
      return dinners.length === 1
        ? 'You have 1 upcoming dinner.'
        : `You have ${dinners.length} upcoming dinners.`;
    }
    case 'get_open_dinners_nearby': {
      const dinners = Array.isArray(toolResult.result.dinners) ? toolResult.result.dinners : [];
      const city = optionalString(toolResult.result.city);
      if (!city) {
        return dinners.length === 1
          ? 'I found 1 open dinner nearby.'
          : `I found ${dinners.length} open dinners nearby.`;
      }
      return dinners.length === 1
        ? `I found 1 open dinner near ${city}.`
        : `I found ${dinners.length} open dinners near ${city}.`;
    }
    case 'create_circle': {
      if (toolResult.result.success === false) {
        return optionalString(toolResult.result.error)
          ?? 'I could not create that circle yet.';
      }

      const circle = toolResult.result.circle;
      if (!circle || typeof circle !== 'object') {
        return 'Your circle is live.';
      }

      const circleName = optionalString((circle as Record<string, unknown>).name) ?? 'your circle';
      return `${circleName} is live.`;
    }
    default:
      return null;
  }
}

function summarizeToolActivityDetail(
  toolResult: { name: string; result: Record<string, unknown> },
): string | undefined {
  switch (toolResult.name) {
    case 'get_my_circles': {
      const circles = Array.isArray(toolResult.result.circles) ? toolResult.result.circles : [];
      return circles.length === 1 ? '1 circle' : `${circles.length} circles`;
    }
    case 'get_upcoming_dinners': {
      const dinners = Array.isArray(toolResult.result.dinners) ? toolResult.result.dinners : [];
      return dinners.length === 1 ? '1 dinner' : `${dinners.length} dinners`;
    }
    case 'get_open_dinners_nearby': {
      const city = optionalString(toolResult.result.city);
      return city ? `${city} · this weekend` : 'nearby';
    }
    case 'create_circle': {
      const circleName = optionalString(toolResult.result.name);
      return circleName ?? 'circle created';
    }
    default:
      return undefined;
  }
}

type ToolName =
  | 'get_upcoming_dinners'
  | 'get_my_circles'
  | 'get_open_dinners_nearby';

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
