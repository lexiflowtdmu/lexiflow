// ============================================================
// Bookmarks Routes — /api/v1/bookmarks/*
// ============================================================

import { Hono } from 'hono';
import type { AuthContext, Bindings, Variables } from '../types';
import { sanitizeString, getValidWordParam } from '../utils/sanitize';

const bookmarks = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET /api/v1/bookmarks — Lấy danh sách word IDs đã bookmark
bookmarks.get('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const result = await db
      .prepare('SELECT word FROM bookmarks WHERE uid = ?')
      .bind(uid)
      .all();

    const words = result.results.map((row) => (row as { word: string }).word);

    return c.json({
      success: true,
      words,
    });
  } catch (error) {
    console.error('Error fetching bookmarks:', error);
    return c.json({ success: false, error: 'Không thể tải danh sách bookmark.' }, 500);
  }
});

// GET /api/v1/bookmarks/list — Lấy danh sách bookmark đầy đủ (word + translation)
bookmarks.get('/list', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const result = await db
      .prepare('SELECT word, translation FROM bookmarks WHERE uid = ? ORDER BY word ASC')
      .bind(uid)
      .all();

    return c.json({
      success: true,
      bookmarks: result.results,
    });
  } catch (error) {
    console.error('Error fetching bookmark list:', error);
    return c.json({ success: false, error: 'Không thể tải danh sách bookmark.' }, 500);
  }
});

// GET /api/v1/bookmarks/:word — Kiểm tra 1 từ đã bookmark chưa
bookmarks.get('/:word', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const word = getValidWordParam(c);

  if (!word) {
    return c.json({ success: false, error: 'Từ vựng không hợp lệ.' }, 400);
  }

  try {
    const result = await db
      .prepare('SELECT 1 as exists_flag FROM bookmarks WHERE uid = ? AND word = ?')
      .bind(uid, word)
      .first();

    return c.json({
      success: true,
      word,
      isBookmarked: result !== null,
    });
  } catch (error) {
    console.error('Error checking bookmark:', error);
    return c.json({ success: false, error: 'Không thể kiểm tra bookmark.' }, 500);
  }
});

// POST /api/v1/bookmarks — Toggle bookmark (thêm hoặc xóa)
bookmarks.post('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body = await c.req.json<{
      word?: string;
      makeBookmarked?: boolean;
      translation?: string;
    }>();
    const word = (body.word ?? '').trim().toLowerCase();
    const makeBookmarked = body.makeBookmarked ?? false;
    const translation = sanitizeString(body.translation ?? '', 2000);

    if (!word) {
      return c.json({ success: false, error: 'Từ vựng không được để trống.' }, 400);
    }

    if (makeBookmarked) {
      // Thêm bookmark (INSERT OR REPLACE)
      await db
        .prepare(
          `INSERT OR REPLACE INTO bookmarks (uid, word, translation, created_at)
           VALUES (?, ?, ?, datetime('now'))`
        )
        .bind(uid, word, translation)
        .run();
    } else {
      // Xóa bookmark
      await db
        .prepare('DELETE FROM bookmarks WHERE uid = ? AND word = ?')
        .bind(uid, word)
        .run();
    }

    return c.json({ success: true });
  } catch (error) {
    console.error('Error toggling bookmark:', error);
    return c.json({ success: false, error: 'Không thể cập nhật bookmark.' }, 500);
  }
});

export default bookmarks;
