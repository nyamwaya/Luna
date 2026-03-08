import { query } from './_generated/server';

/// Lightweight health check query for client connectivity checks.
export const ping = query({
  args: {},
  handler: async () => {
    return 'ok';
  },
});
