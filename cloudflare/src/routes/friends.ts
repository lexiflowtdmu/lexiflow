import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse, Friendship, FriendUser } from '../types/index.js';

export const friendRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

/**
 * POST /api/friends/request
 * Send a friend request from requester_uid to receiver_uid
 */
friendRoutes.post('/request', async (c) => {
  try {
    const { uid: requesterUid } = c.get('auth');
    const body = await c.req.json<{ receiverUid: string }>();

    if (!body.receiverUid) {
      return c.json<ApiResponse>({ success: false, error: 'Missing receiverUid' }, 400);
    }

    if (requesterUid === body.receiverUid) {
      return c.json<ApiResponse>({ success: false, error: 'Cannot send friend request to yourself' }, 400);
    }

    const db = c.env.DB;

    // Check if friendship or request already exists
    const existing = await db
      .prepare(
        `SELECT * FROM friendships
         WHERE (requester_uid = ? AND receiver_uid = ?)
            OR (requester_uid = ? AND receiver_uid = ?)`
      )
      .bind(requesterUid, body.receiverUid, body.receiverUid, requesterUid)
      .first<Friendship>();

    if (existing) {
      if (existing.status === 'accepted') {
        return c.json<ApiResponse>({ success: false, error: 'Already friends' }, 400);
      }
      if (existing.status === 'pending') {
        return c.json<ApiResponse>({ success: false, error: 'Friend request already pending' }, 400);
      }
    }

    const id = `fr-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;

    await db
      .prepare(
        `INSERT INTO friendships (id, requester_uid, receiver_uid, status, created_at, updated_at)
         VALUES (?, ?, ?, 'pending', datetime('now'), datetime('now'))
         ON CONFLICT(requester_uid, receiver_uid) DO UPDATE SET
           status = 'pending',
           updated_at = datetime('now')`
      )
      .bind(id, requesterUid, body.receiverUid)
      .run();

    return c.json<ApiResponse<{ message: string; id: string }>>({
      success: true,
      data: { message: 'Friend request sent successfully', id }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * POST /api/friends/respond
 * Accept, Reject, or Block a friend request
 */
friendRoutes.post('/respond', async (c) => {
  try {
    const { uid: receiverUid } = c.get('auth');
    const body = await c.req.json<{
      requesterUid: string;
      action: 'accept' | 'reject' | 'block';
    }>();

    if (!body.requesterUid || !body.action) {
      return c.json<ApiResponse>({ success: false, error: 'Missing parameters' }, 400);
    }

    const db = c.env.DB;

    let newStatus = 'rejected';
    if (body.action === 'accept') newStatus = 'accepted';
    if (body.action === 'block') newStatus = 'blocked';

    if (body.action === 'reject') {
      await db
        .prepare(
          `DELETE FROM friendships
           WHERE requester_uid = ? AND receiver_uid = ?`
        )
        .bind(body.requesterUid, receiverUid)
        .run();
    } else {
      await db
        .prepare(
          `UPDATE friendships
           SET status = ?, updated_at = datetime('now')
           WHERE requester_uid = ? AND receiver_uid = ?`
        )
        .bind(newStatus, body.requesterUid, receiverUid)
        .run();
    }

    return c.json<ApiResponse<{ message: string }>>({
      success: true,
      data: { message: `Friend request ${body.action}ed successfully` }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/friends/list?uid=...
 * Fetch accepted friends list for a user
 */
friendRoutes.get('/list', async (c) => {
  try {
    const { uid } = c.get('auth');

    const db = c.env.DB;

    const friendsRes = await db
      .prepare(
        `SELECT u.*, s.current_streak
         FROM friendships f
         JOIN users u ON (
           CASE 
             WHEN f.requester_uid = ? THEN u.uid = f.receiver_uid
             ELSE u.uid = f.requester_uid
           END
         )
         LEFT JOIN study_streaks s ON u.uid = s.uid
         WHERE (f.requester_uid = ? OR f.receiver_uid = ?) 
           AND f.status = 'accepted'`
      )
      .bind(uid, uid, uid)
      .all<FriendUser>();

    return c.json<ApiResponse<FriendUser[]>>({
      success: true,
      data: friendsRes.results
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/friends/requests?uid=...
 * Fetch incoming pending friend requests for a user
 */
friendRoutes.get('/requests', async (c) => {
  try {
    const { uid } = c.get('auth');

    const db = c.env.DB;

    const requestsRes = await db
      .prepare(
        `SELECT u.*, f.id as friendship_id, f.created_at as request_date
         FROM friendships f
         JOIN users u ON u.uid = f.requester_uid
         WHERE f.receiver_uid = ? AND f.status = 'pending'`
      )
      .bind(uid)
      .all<FriendUser & { friendship_id: string; request_date: string }>();

    return c.json<ApiResponse<typeof requestsRes.results>>({
      success: true,
      data: requestsRes.results
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * DELETE /api/friends/unfriend
 * Remove a friend
 */
friendRoutes.delete('/unfriend', async (c) => {
  try {
    const { uid: uid1 } = c.get('auth');
    const uid2 = c.req.query('uid2');

    if (!uid2) {
      return c.json<ApiResponse>({ success: false, error: 'Missing uid2 query parameter' }, 400);
    }

    const db = c.env.DB;

    await db
      .prepare(
        `DELETE FROM friendships
         WHERE (requester_uid = ? AND receiver_uid = ?)
            OR (requester_uid = ? AND receiver_uid = ?)`
      )
      .bind(uid1, uid2, uid2, uid1)
      .run();

    return c.json<ApiResponse<{ message: string }>>({
      success: true,
      data: { message: 'Unfriended successfully' }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});
