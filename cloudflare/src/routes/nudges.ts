import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse } from '../types/index.js';

export const nudgeRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

export interface SocialNudgeItem {
  id: string;
  sender_uid: string;
  sender_name?: string;
  sender_avatar?: string;
  receiver_uid: string;
  type: 'cheer' | 'nudge';
  message: string;
  is_read: number;
  created_at: string;
}

/**
 * POST /api/nudges/send
 * Send a cheer or streak reminder nudge to a friend
 */
nudgeRoutes.post('/send', async (c) => {
  try {
    const { uid: senderUid } = c.get('auth');
    const body = await c.req.json<{
      receiverUid: string;
      type: 'cheer' | 'nudge';
      message?: string;
    }>();

    if (!body.receiverUid || !body.type) {
      return c.json<ApiResponse>({ success: false, error: 'Missing receiverUid or type' }, 400);
    }

    const db = c.env.DB;
    const id = `nudge-${Date.now()}`;
    const defaultMsg =
      body.type === 'cheer'
        ? '🎉 Bạn vừa nhận được 1 lượt thả tim chúc mừng học tập xuất sắc!'
        : '🔥 Ê bạn ơi, hôm nay chưa học kìa! Đăng nhập làm bài ngay kẻo đứt streak nhé!';

    await db
      .prepare(
        `INSERT INTO social_nudges (id, sender_uid, receiver_uid, type, message, is_read, created_at)
         VALUES (?, ?, ?, ?, ?, 0, datetime('now'))`
      )
      .bind(id, senderUid, body.receiverUid, body.type, body.message || defaultMsg)
      .run();

    return c.json<ApiResponse<{ id: string; message: string }>>({
      success: true,
      data: { id, message: 'Social nudge sent successfully' }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/nudges/my-nudges?uid=...
 * Get list of nudges/cheers received by a user
 */
nudgeRoutes.get('/my-nudges', async (c) => {
  try {
    const { uid } = c.get('auth');

    const db = c.env.DB;
    const res = await db
      .prepare(
        `SELECT n.*, u.display_name as sender_name, u.avatar_url as sender_avatar
         FROM social_nudges n
         JOIN users u ON u.uid = n.sender_uid
         WHERE n.receiver_uid = ?
         ORDER BY n.created_at DESC
         LIMIT 30`
      )
      .bind(uid)
      .all<SocialNudgeItem>();

    return c.json<ApiResponse<SocialNudgeItem[]>>({
      success: true,
      data: res.results
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});
