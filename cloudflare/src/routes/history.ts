// ============================================================
// Search History Routes — /api/v1/history/*
// ============================================================

import { Hono } from 'hono';
import type { AuthContext, Bindings, Variables } from '../types';
import { sanitizeString, getValidWordParam } from '../utils/sanitize';

const history = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET /api/v1/history — Lấy lịch sử tra từ (tối đa 30)
history.get('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const result = await db
      .prepare('SELECT * FROM search_history WHERE uid = ? ORDER BY timestamp DESC LIMIT 30')
      .bind(uid)
      .all();

    return c.json({
      success: true,
      history: result.results,
    });
  } catch (error) {
    console.error('Error fetching history:', error);
    return c.json({ success: false, error: 'Không thể tải lịch sử tra từ.' }, 500);
  }
});

// POST /api/v1/history — Thêm/cập nhật mục lịch sử
history.post('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body = await c.req.json<{ word?: string; translation?: string }>();
    const word = (body.word ?? '').trim().toLowerCase();
    const translation = sanitizeString(body.translation ?? '', 2000);

    if (!word) {
      return c.json({ success: false, error: 'Từ vựng không được để trống.' }, 400);
    }

    // Upsert: nếu cặp (uid, word) đã tồn tại thì UPDATE timestamp
    // Generate ID once to avoid conflicts
    const id = crypto.randomUUID();
    await db
      .prepare(
        `INSERT INTO search_history (id, uid, word, translation, timestamp)
         VALUES (?, ?, ?, ?, datetime('now'))
         ON CONFLICT(uid, word) DO UPDATE SET
           translation = excluded.translation,
           timestamp = datetime('now'),
           id = excluded.id`
      )
      .bind(id, uid, word, translation)
      .run();

    return c.json({ success: true });
  } catch (error) {
    console.error('Error adding history:', error);
    return c.json({ success: false, error: 'Không thể lưu lịch sử tra từ.' }, 500);
  }
});

// DELETE /api/v1/history — Xóa toàn bộ lịch sử
history.delete('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    await db
      .prepare('DELETE FROM search_history WHERE uid = ?')
      .bind(uid)
      .run();

    return c.json({ success: true });
  } catch (error) {
    console.error('Error clearing history:', error);
    return c.json({ success: false, error: 'Không thể xóa lịch sử.' }, 500);
  }
});

// DELETE /api/v1/history/:word — Xóa 1 mục lịch sử
history.delete('/:word', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const word = getValidWordParam(c);

  if (!word) {
    return c.json({ success: false, error: 'Từ vựng không hợp lệ.' }, 400);
  }

  try {
    await db
      .prepare('DELETE FROM search_history WHERE uid = ? AND word = ?')
      .bind(uid, word)
      .run();

    return c.json({ success: true });
  } catch (error) {
    console.error('Error deleting history item:', error);
    return c.json({ success: false, error: 'Không thể xóa mục lịch sử.' }, 500);
  }
});

export default history;
