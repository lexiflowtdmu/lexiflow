// ============================================================
// Admin Routes — /api/v1/admin/*
// All endpoints require ADMIN_UIDS env var to contain the caller's uid
// ============================================================

import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse } from '../types/index.js';

export const adminRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function isAdmin(c: any): boolean {
  const { uid } = c.get('auth');
  const adminUids = (c.env.ADMIN_UIDS || '').split(',').map((s: string) => s.trim()).filter(Boolean);
  return adminUids.includes(uid);
}

// ─── Stats ────────────────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/stats
 * System-wide overview: users, cards, activity, farm
 */
adminRoutes.get('/stats', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;

  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

  const [
    usersRes,
    cardsRes,
    coinsRes,
    farmOrdersRes,
    todayActiveRes,
    todayReviewsRes,
    newUsersRes,
  ] = await db.batch([
    db.prepare('SELECT COUNT(*) as n FROM users'),
    db.prepare('SELECT COUNT(*) as n FROM flashcards'),
    db.prepare('SELECT SUM(coins) as n FROM user_pets'),
    db.prepare("SELECT COUNT(*) as n FROM farm_orders WHERE status='fulfilled'"),
    db.prepare(
      `SELECT COUNT(DISTINCT uid) as n FROM review_logs WHERE DATE(server_time) = ?`
    ).bind(today),
    db.prepare(
      `SELECT COUNT(*) as n FROM review_logs WHERE DATE(server_time) = ?`
    ).bind(today),
    db.prepare(
      `SELECT COUNT(*) as n FROM users WHERE DATE(created_at) = ?`
    ).bind(today),
  ]);

  return c.json({
    success: true,
    data: {
      total_users:       (usersRes as any).results?.[0]?.n ?? 0,
      total_cards:       (cardsRes as any).results?.[0]?.n ?? 0,
      total_coins:       (coinsRes as any).results?.[0]?.n ?? 0,
      fulfilled_orders:  (farmOrdersRes as any).results?.[0]?.n ?? 0,
      active_today:      (todayActiveRes as any).results?.[0]?.n ?? 0,
      reviews_today:     (todayReviewsRes as any).results?.[0]?.n ?? 0,
      new_users_today:   (newUsersRes as any).results?.[0]?.n ?? 0,
    }
  });
});

// ─── Users ────────────────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/users?q=&limit=20&offset=0
 * Paginated user list with streak + coins joined
 */
adminRoutes.get('/users', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const q = (c.req.query('q') || '').trim();
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 50);
  const offset = parseInt(c.req.query('offset') || '0');

  let stmt;
  if (q) {
    const like = `%${q}%`;
    stmt = db
      .prepare(
        `SELECT u.uid, u.email, u.display_name, u.avatar_url, u.user_code,
                u.level, u.xp, u.created_at, u.last_active_at,
                s.current_streak,
                p.coins, p.pet_name
         FROM users u
         LEFT JOIN study_streaks s ON s.uid = u.uid
         LEFT JOIN user_pets p ON p.uid = u.uid
         WHERE u.uid LIKE ? OR u.display_name LIKE ? OR u.email LIKE ? OR u.user_code LIKE ?
         ORDER BY u.xp DESC LIMIT ? OFFSET ?`
      )
      .bind(like, like, like, like, limit, offset);
  } else {
    stmt = db
      .prepare(
        `SELECT u.uid, u.email, u.display_name, u.avatar_url, u.user_code,
                u.level, u.xp, u.created_at, u.last_active_at,
                s.current_streak,
                p.coins, p.pet_name
         FROM users u
         LEFT JOIN study_streaks s ON s.uid = u.uid
         LEFT JOIN user_pets p ON p.uid = u.uid
         ORDER BY u.xp DESC LIMIT ? OFFSET ?`
      )
      .bind(limit, offset);
  }

  const res = await stmt.all();
  return c.json({ success: true, data: res.results });
});

/**
 * GET /api/v1/admin/users/:uid
 * Full profile of a single user
 */
adminRoutes.get('/users/:uid', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const targetUid = c.req.param('uid');

  const [userRes, streakRes, petRes, cardCountRes, reviewsRes] = await db.batch([
    db.prepare('SELECT * FROM users WHERE uid = ?').bind(targetUid),
    db.prepare('SELECT * FROM study_streaks WHERE uid = ?').bind(targetUid),
    db.prepare('SELECT * FROM user_pets WHERE uid = ?').bind(targetUid),
    db.prepare('SELECT COUNT(*) as n FROM flashcards WHERE uid = ?').bind(targetUid),
    db.prepare(
      `SELECT COUNT(*) as n FROM review_logs WHERE uid = ? AND DATE(server_time) = DATE('now')`
    ).bind(targetUid),
  ]);

  const user = (userRes as any).results?.[0];
  if (!user) return c.json<ApiResponse>({ success: false, error: 'User không tồn tại' }, 404);

  return c.json({
    success: true,
    data: {
      user,
      streak: (streakRes as any).results?.[0] ?? null,
      pet: (petRes as any).results?.[0] ?? null,
      total_cards: (cardCountRes as any).results?.[0]?.n ?? 0,
      reviews_today: (reviewsRes as any).results?.[0]?.n ?? 0,
    }
  });
});

/**
 * PATCH /api/v1/admin/users/:uid
 * Edit user: grant xp, set level, rename, grant/deduct coins
 */
adminRoutes.patch('/users/:uid', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const targetUid = c.req.param('uid');
  const body = await c.req.json<{
    grant_xp?: number;
    set_level?: number;
    display_name?: string;
    grant_coins?: number;
  }>();

  const userUpdates: string[] = [];
  const userValues: any[] = [];

  if (body.grant_xp !== undefined) {
    const xp = Math.max(-99999, Math.min(Number(body.grant_xp), 99999));
    userUpdates.push('xp = MAX(0, xp + ?)');
    userValues.push(xp);
  }
  if (body.set_level !== undefined) {
    userUpdates.push('level = ?');
    userValues.push(Math.max(1, Math.min(Number(body.set_level), 999)));
  }
  if (body.display_name !== undefined && body.display_name.trim()) {
    userUpdates.push('display_name = ?');
    userValues.push(body.display_name.trim().slice(0, 50));
  }

  const stmts = [];

  if (userUpdates.length > 0) {
    userUpdates.push("updated_at = datetime('now')");
    stmts.push(
      db.prepare(`UPDATE users SET ${userUpdates.join(', ')} WHERE uid = ?`)
        .bind(...userValues, targetUid)
    );
  }

  if (body.grant_coins !== undefined && body.grant_coins !== 0) {
    const coins = Math.max(-99999, Math.min(Number(body.grant_coins), 99999));
    stmts.push(
      db.prepare(
        `INSERT INTO user_pets (uid, coins) VALUES (?, MAX(0, ?))
         ON CONFLICT(uid) DO UPDATE SET coins = MAX(0, coins + ?), updated_at = datetime('now')`
      ).bind(targetUid, Math.max(0, coins), coins)
    );
  }

  if (stmts.length === 0) {
    return c.json<ApiResponse>({ success: false, error: 'Không có gì để cập nhật' }, 400);
  }

  await db.batch(stmts);
  return c.json<ApiResponse>({ success: true });
});

/**
 * DELETE /api/v1/admin/users/:uid
 * Hard-delete a user and all their data
 */
adminRoutes.delete('/users/:uid', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const { uid: adminUid } = c.get('auth');
  const targetUid = c.req.param('uid');

  if (targetUid === adminUid) {
    return c.json<ApiResponse>({ success: false, error: 'Không thể tự xóa tài khoản admin' }, 400);
  }

  const db = c.env.DB;
  await db.batch([
    db.prepare('DELETE FROM flashcards WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM search_history WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM bookmarks WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM study_streaks WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM user_settings WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM user_pets WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM farm_plots WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM farm_inventory WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM farm_orders WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM home_furniture WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM review_logs WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM xp_transactions WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM social_nudges WHERE sender_uid = ? OR receiver_uid = ?').bind(targetUid, targetUid),
    db.prepare('DELETE FROM friendships WHERE requester_uid = ? OR receiver_uid = ?').bind(targetUid, targetUid),
    db.prepare('DELETE FROM group_members WHERE uid = ?').bind(targetUid),
    db.prepare('DELETE FROM users WHERE uid = ?').bind(targetUid),
  ]);

  return c.json<ApiResponse>({ success: true });
});

// ─── Leaderboard ──────────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/leaderboard?limit=10
 * Top users by XP
 */
adminRoutes.get('/leaderboard', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const limit = Math.min(parseInt(c.req.query('limit') || '10'), 50);

  const res = await db
    .prepare(
      `SELECT u.uid, u.display_name, u.avatar_url, u.user_code, u.level, u.xp,
              s.current_streak
       FROM users u
       LEFT JOIN study_streaks s ON s.uid = u.uid
       ORDER BY u.xp DESC LIMIT ?`
    )
    .bind(limit)
    .all();

  return c.json({ success: true, data: res.results });
});

// ─── Farm Stats ───────────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/farm/stats
 * Farm system stats: top farmers, inventory totals
 */
adminRoutes.get('/farm/stats', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;

  const [topCoinsRes, invRes, ordersRes] = await db.batch([
    db.prepare(
      `SELECT u.display_name, u.user_code, p.coins, p.pet_name
       FROM user_pets p JOIN users u ON u.uid = p.uid
       ORDER BY p.coins DESC LIMIT 10`
    ),
    db.prepare(
      `SELECT item_type, SUM(quantity) as total FROM farm_inventory GROUP BY item_type ORDER BY total DESC`
    ),
    db.prepare(
      `SELECT status, COUNT(*) as n FROM farm_orders GROUP BY status`
    ),
  ]);

  return c.json({
    success: true,
    data: {
      top_coin_users: (topCoinsRes as any).results ?? [],
      inventory_totals: (invRes as any).results ?? [],
      order_breakdown: (ordersRes as any).results ?? [],
    }
  });
});

// ─── Ban / Unban ──────────────────────────────────────────────────────────────

/**
 * POST /api/v1/admin/users/:uid/ban
 * Lock a user account (sets is_banned = 1)
 */
adminRoutes.post('/users/:uid/ban', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const { uid: adminUid } = c.get('auth');
  const targetUid = c.req.param('uid');

  if (targetUid === adminUid) {
    return c.json<ApiResponse>({ success: false, error: 'Không thể tự khóa tài khoản admin' }, 400);
  }

  const db = c.env.DB;
  const body = await c.req.json<{ reason?: string }>().catch(() => ({}));
  const reason = (body.reason ?? '').trim().slice(0, 255) || 'Vi phạm điều khoản sử dụng';

  await db.prepare(
    `UPDATE users SET is_banned = 1, banned_reason = ?, banned_at = datetime('now'), updated_at = datetime('now') WHERE uid = ?`
  ).bind(reason, targetUid).run();

  return c.json<ApiResponse>({ success: true });
});

/**
 * POST /api/v1/admin/users/:uid/unban
 * Unlock a user account (sets is_banned = 0)
 */
adminRoutes.post('/users/:uid/unban', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const targetUid = c.req.param('uid');
  const db = c.env.DB;

  await db.prepare(
    `UPDATE users SET is_banned = 0, banned_reason = NULL, banned_at = NULL, updated_at = datetime('now') WHERE uid = ?`
  ).bind(targetUid).run();

  return c.json<ApiResponse>({ success: true });
});

// ─── Reset Password (via Firebase REST API) ───────────────────────────────────

/**
 * POST /api/v1/admin/users/:uid/reset-password
 * Sends a Firebase password-reset email to the user
 * Requires FIREBASE_API_KEY env var
 */
adminRoutes.post('/users/:uid/reset-password', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const targetUid = c.req.param('uid');

  const user = await db.prepare('SELECT email FROM users WHERE uid = ?').bind(targetUid).first<{ email: string }>();
  if (!user) return c.json<ApiResponse>({ success: false, error: 'User không tồn tại' }, 404);

  const apiKey = (c.env as any).FIREBASE_API_KEY;
  if (!apiKey) {
    return c.json<ApiResponse>({ success: false, error: 'FIREBASE_API_KEY chưa được cấu hình' }, 500);
  }

  const resp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ requestType: 'PASSWORD_RESET', email: user.email }),
    }
  );

  if (!resp.ok) {
    const err = await resp.json() as any;
    const msg = err?.error?.message ?? 'Không thể gửi email reset mật khẩu';
    return c.json<ApiResponse>({ success: false, error: msg }, 500);
  }

  return c.json({ success: true, data: { email: user.email } });
});

// ─── Content Curation ─────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/content/candidates?limit=20&offset=0
 * High-quality user flashcards (repetitions >= 3, ease_factor >= 2.0)
 * suitable for promotion to base data, excluding already-curated words
 */
adminRoutes.get('/content/candidates', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 50);
  const offset = parseInt(c.req.query('offset') || '0');
  const q = (c.req.query('q') || '').trim();

  let stmt;
  if (q) {
    const like = `%${q}%`;
    stmt = db.prepare(
      `SELECT f.id, f.word, f.meaning, f.example, f.repetitions, f.ease_factor, f.uid,
              u.display_name, u.user_code,
              (SELECT 1 FROM curated_content cc WHERE cc.word = f.word LIMIT 1) as already_curated
       FROM flashcards f
       JOIN users u ON u.uid = f.uid
       WHERE f.repetitions >= 3 AND f.ease_factor >= 2.0
         AND (f.word LIKE ? OR f.meaning LIKE ?)
       ORDER BY f.repetitions DESC, f.ease_factor DESC
       LIMIT ? OFFSET ?`
    ).bind(like, like, limit, offset);
  } else {
    stmt = db.prepare(
      `SELECT f.id, f.word, f.meaning, f.example, f.repetitions, f.ease_factor, f.uid,
              u.display_name, u.user_code,
              (SELECT 1 FROM curated_content cc WHERE cc.word = f.word LIMIT 1) as already_curated
       FROM flashcards f
       JOIN users u ON u.uid = f.uid
       WHERE f.repetitions >= 3 AND f.ease_factor >= 2.0
       ORDER BY f.repetitions DESC, f.ease_factor DESC
       LIMIT ? OFFSET ?`
    ).bind(limit, offset);
  }

  const res = await stmt.all();
  return c.json({ success: true, data: res.results });
});

/**
 * GET /api/v1/admin/content/curated?limit=30&offset=0
 * List all curated base-data entries
 */
adminRoutes.get('/content/curated', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const limit = Math.min(parseInt(c.req.query('limit') || '30'), 100);
  const offset = parseInt(c.req.query('offset') || '0');

  const res = await db.prepare(
    `SELECT cc.*, u.display_name as promoted_by_name
     FROM curated_content cc
     LEFT JOIN users u ON u.uid = cc.promoted_by
     ORDER BY cc.promoted_at DESC
     LIMIT ? OFFSET ?`
  ).bind(limit, offset).all();

  return c.json({ success: true, data: res.results });
});

/**
 * POST /api/v1/admin/content/curate
 * Promote a flashcard to curated base data
 */
adminRoutes.post('/content/curate', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const { uid: adminUid } = c.get('auth');
  const db = c.env.DB;

  const body = await c.req.json<{
    card_id: string;
    category?: string;
  }>();

  if (!body.card_id) {
    return c.json<ApiResponse>({ success: false, error: 'Thiếu card_id' }, 400);
  }

  const card = await db.prepare('SELECT * FROM flashcards WHERE id = ?').bind(body.card_id).first<{
    id: string; uid: string; word: string; meaning: string; example: string;
  }>();
  if (!card) return c.json<ApiResponse>({ success: false, error: 'Flashcard không tồn tại' }, 404);

  const id = `cur-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
  const category = (body.category ?? 'general').slice(0, 50);

  await db.prepare(
    `INSERT INTO curated_content (id, word, meaning, example, source_uid, source_card_id, category, promoted_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(word) DO UPDATE SET
       meaning = excluded.meaning,
       example = excluded.example,
       category = excluded.category,
       promoted_by = excluded.promoted_by,
       promoted_at = datetime('now')`
  ).bind(id, card.word, card.meaning, card.example, card.uid, card.id, category, adminUid).run();

  return c.json({ success: true, data: { word: card.word } });
});

/**
 * DELETE /api/v1/admin/content/curated/:id
 * Remove an entry from curated base data
 */
adminRoutes.delete('/content/curated/:id', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const id = c.req.param('id');
  await db.prepare('DELETE FROM curated_content WHERE id = ?').bind(id).run();
  return c.json<ApiResponse>({ success: true });
});

// ─── Recent Activity ──────────────────────────────────────────────────────────

/**
 * GET /api/v1/admin/activity?days=7
 * Daily review counts for last N days
 */
adminRoutes.get('/activity', async (c) => {
  if (!isAdmin(c)) return c.json<ApiResponse>({ success: false, error: 'Forbidden' }, 403);
  const db = c.env.DB;
  const days = Math.min(parseInt(c.req.query('days') || '7'), 30);

  const res = await db
    .prepare(
      `SELECT DATE(server_time) as date,
              COUNT(*) as reviews,
              COUNT(DISTINCT uid) as active_users
       FROM review_logs
       WHERE server_time >= datetime('now', ? || ' days')
       GROUP BY DATE(server_time)
       ORDER BY date ASC`
    )
    .bind(`-${days}`)
    .all();

  return c.json({ success: true, data: res.results });
});
