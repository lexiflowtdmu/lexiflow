// ============================================================
// LexiFlow Cloudflare Worker API — Entry Point
// ============================================================

import { Hono } from 'hono';
import { corsMiddleware } from './middleware/cors';
import { authMiddleware } from './middleware/auth';
import { rateLimitMiddleware } from './middleware/rateLimit';
import flashcards from './routes/flashcards';
import history from './routes/history';
import bookmarks from './routes/bookmarks';
import streak from './routes/streak';
import { userRoutes } from './routes/users';
import { friendRoutes } from './routes/friends';
import { groupRoutes } from './routes/groups';
import { deckRoutes } from './routes/decks';
import { nudgeRoutes } from './routes/nudges';
import { battleRoutes } from './routes/battle';
import { farmRoutes } from './routes/farm';
import { homeRoutes } from './routes/home';
import { adminRoutes } from './routes/admin';
import type { Bindings, Variables } from './types';

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// --- Global Middleware ---
app.use('*', corsMiddleware);
app.use('*', rateLimitMiddleware({ maxRequests: 100, windowMs: 60000 })); // 100 requests per minute

// --- Public Routes (no auth) ---
app.get('/api/v1/health', (c) => {
  return c.json({
    status: 'ok',
    service: 'LexiFlow API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// --- Protected Routes (auth required) ---
const api = new Hono<{ Bindings: Bindings; Variables: Variables }>();
api.use('*', authMiddleware);

api.route('/flashcards', flashcards);
api.route('/history', history);
api.route('/bookmarks', bookmarks);
api.route('/streak', streak);
api.route('/users', userRoutes);
api.route('/friends', friendRoutes);
api.route('/groups', groupRoutes);
api.route('/decks', deckRoutes);
api.route('/nudges', nudgeRoutes);
api.route('/battle', battleRoutes);
api.route('/farm', farmRoutes);
api.route('/home', homeRoutes);
api.route('/admin', adminRoutes);

app.route('/api/v1', api);

// --- Not Found Handler ---
app.notFound((c) => {
  return c.json(
    {
      success: false,
      error: `Endpoint không tồn tại: ${c.req.method} ${c.req.path}`,
    },
    404
  );
});

// --- Error Handler ---
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json(
    {
      success: false,
      error: 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
    },
    500
  );
});

export default app;
