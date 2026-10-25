// ============================================================
// Flashcards Routes — /api/v1/flashcards/*
// ============================================================

import { Hono } from 'hono';
import type { AuthContext, Bindings, Variables, FlashcardInput } from '../types';
import { sanitizeString, sanitizeWord } from '../utils/sanitize';
import { recalculateSM2FromEvents } from '../utils/sm2Engine';

const flashcards = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET /api/v1/flashcards — Lấy tất cả flashcards của user
flashcards.get('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const result = await db
      .prepare('SELECT * FROM flashcards WHERE uid = ? ORDER BY next_review ASC')
      .bind(uid)
      .all();

    return c.json({
      success: true,
      vocabs: result.results,
    });
  } catch (error) {
    console.error('Error fetching flashcards:', error);
    return c.json({ success: false, error: 'Không thể tải danh sách flashcards.' }, 500);
  }
});

// GET /api/v1/flashcards/due — Lấy flashcards đến hạn ôn tập (Kèm Catch-up Mode Suggestion khi > 100 từ)
flashcards.get('/due', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const catchupThreshold = Number(c.req.query('threshold') || 100);

  try {
    const result = await db
      .prepare("SELECT * FROM flashcards WHERE uid = ? AND next_review <= datetime('now') ORDER BY next_review ASC")
      .bind(uid)
      .all();

    const vocabs = result.results || [];
    const totalDue = vocabs.length;
    const suggestCatchup = totalDue > catchupThreshold;

    return c.json({
      success: true,
      total_due: totalDue,
      suggest_catchup: suggestCatchup,
      catchup_threshold: catchupThreshold,
      vocabs: suggestCatchup ? vocabs.slice(0, 15) : vocabs,
    });
  } catch (error) {
    console.error('Error fetching due flashcards:', error);
    return c.json({ success: false, error: 'Không thể tải danh sách flashcards đến hạn.' }, 500);
  }
});

// POST /api/v1/flashcards/catch-up/start — Bắt đầu phiên học giảm áp lực (15 từ) + Cấp Streak Freeze tuần
flashcards.post('/catch-up/start', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    // 1. Fetch top 15 most overdue cards
    const result = await db
      .prepare(
        `SELECT * FROM flashcards
         WHERE uid = ? AND next_review <= datetime('now')
         ORDER BY next_review ASC, ease_factor ASC
         LIMIT 15`
      )
      .bind(uid)
      .all();

    // 2. Check and apply weekly streak freeze (max 1 grant per 7 days)
    const nowISO = new Date().toISOString();
    const freezeRow = await db
      .prepare('SELECT * FROM user_streak_freezes WHERE uid = ?')
      .bind(uid)
      .first<any>();

    let streakFreezeGranted = false;
    let availableFreezes = freezeRow?.available_freezes || 0;
    const lastGrantedAt = freezeRow?.last_granted_at || '';

    const daysSinceLastGrant = lastGrantedAt
      ? (Date.now() - new Date(lastGrantedAt).getTime()) / (1000 * 60 * 60 * 24)
      : 999;

    if (daysSinceLastGrant >= 7) {
      availableFreezes += 1;
      streakFreezeGranted = true;

      await db
        .prepare(
          `INSERT INTO user_streak_freezes (uid, available_freezes, last_granted_at, used_count, updated_at)
           VALUES (?, ?, ?, 0, datetime('now'))
           ON CONFLICT(uid) DO UPDATE SET
             available_freezes = excluded.available_freezes,
             last_granted_at = excluded.last_granted_at,
             updated_at = datetime('now')`
        )
        .bind(uid, availableFreezes, nowISO)
        .run();
    }

    return c.json({
      success: true,
      session_size: result.results?.length || 0,
      streak_freeze_granted: streakFreezeGranted,
      available_freezes: availableFreezes,
      vocabs: result.results || []
    });
  } catch (error) {
    console.error('Error starting Catch-up mode:', error);
    return c.json({ success: false, error: 'Không thể bắt đầu chế độ Catch-up.' }, 500);
  }
});

// POST /api/v1/flashcards/catch-up/reschedule — Giãn lịch ôn tập của phần nợ backlog dư thừa
flashcards.post('/catch-up/reschedule', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body = await c.req.json<{ keep_top?: number; spread_days?: number }>();
    const keepTop = body.keep_top ?? 15;
    const spreadDays = Math.min(Math.max(body.spread_days ?? 7, 1), 14);

    // Fetch all overdue cards beyond top 15
    const overdueResult = await db
      .prepare(
        `SELECT id FROM flashcards
         WHERE uid = ? AND next_review <= datetime('now')
         ORDER BY next_review ASC
         OFFSET ?`
      )
      .bind(uid, keepTop)
      .all<{ id: string }>();

    const backlogCards = overdueResult.results || [];

    if (backlogCards.length > 0) {
      const batchUpdates = backlogCards.map((card, i) => {
        const dayOffset = (i % spreadDays) + 1;
        return db.prepare(
          `UPDATE flashcards
           SET next_review = datetime('now', '+' || ? || ' days'),
               updated_at = datetime('now')
           WHERE id = ? AND uid = ?`
        ).bind(dayOffset, card.id, uid);
      });
      await db.batch(batchUpdates);
    }

    return c.json({
      success: true,
      rescheduled_count: backlogCards.length,
      spread_days: spreadDays
    });
  } catch (error) {
    console.error('Error rescheduling Catch-up backlog:', error);
    return c.json({ success: false, error: 'Không thể giãn lịch Catch-up backlog.' }, 500);
  }
});


// POST /api/v1/flashcards — Tạo mới hoặc cập nhật flashcard
flashcards.post('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body: FlashcardInput = await c.req.json();

    // Sanitize inputs
    const word = sanitizeWord(body.word || '');
    const meaning = sanitizeString(body.meaning || '', 2000);
    const example = sanitizeString(body.example || '', 2000);

    // Extract values with robust defaults (supporting both camelCase and snake_case)
    const interval = body.interval ?? 0;
    const easeFactor = body.easeFactor ?? body.ease_factor ?? 2.5;
    const repetitions = body.repetitions ?? 0;
    const nextReview = body.nextReview ?? body.next_review ?? new Date().toISOString();


    if (!word || word.trim().length === 0) {
      return c.json({ success: false, error: 'Từ vựng không được để trống.' }, 400);
    }

    // Validate required fields for new flashcards
    if (!body.id || body.id.length === 0) {
      if (meaning.trim().length === 0) {
        return c.json({ success: false, error: 'Nghĩa của từ không được để trống.' }, 400);
      }
    }

    if (body.id && body.id.length > 0) {
      // Update existing flashcard
      const result = await db
        .prepare(
          `UPDATE flashcards
           SET word = ?, meaning = ?, example = ?, interval = ?,
               ease_factor = ?, repetitions = ?, next_review = ?,
               updated_at = datetime('now')
           WHERE id = ? AND uid = ?`
        )
        .bind(
          word, meaning, example, interval,
          easeFactor, repetitions, nextReview,
          body.id, uid
        )
        .run();

      // Check if any row was updated
      if (result.meta.changes === 0) {
        return c.json({ success: false, error: 'Flashcard không tồn tại hoặc không thuộc về bạn.' }, 404);
      }

      return c.json({ success: true, id: body.id });
    } else {
      // Create new flashcard
      const id = crypto.randomUUID();
      await db
        .prepare(
          `INSERT INTO flashcards (id, uid, word, meaning, example, interval, ease_factor, repetitions, next_review)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
        )
        .bind(
          id, uid, word, meaning, example,
          interval, easeFactor, repetitions, nextReview
        )
        .run();

      return c.json({ success: true, id }, 201);
    }

  } catch (error) {
    console.error('Error saving flashcard:', error);
    return c.json({ success: false, error: 'Không thể lưu flashcard.' }, 500);
  }
});

// DELETE /api/v1/flashcards/:id — Xóa 1 flashcard
flashcards.delete('/:id', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const id = c.req.param('id');

  try {
    const result = await db
      .prepare('DELETE FROM flashcards WHERE id = ? AND uid = ?')
      .bind(id, uid)
      .run();

    if (result.meta.changes === 0) {
      return c.json({ success: false, error: 'Flashcard không tồn tại hoặc không thuộc về bạn.' }, 404);
    }

    return c.json({ success: true });
  } catch (error) {
    console.error('Error deleting flashcard:', error);
    return c.json({ success: false, error: 'Không thể xóa flashcard.' }, 500);
  }
});

// POST /api/v1/flashcards/review-events — Append-only review events (Single or Batch Array)
flashcards.post('/review-events', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body = await c.req.json<any>();
    const events: Array<{
      review_id: string;
      card_id: string;
      rating: number;
      client_time: string;
      device_id?: string;
    }> = Array.isArray(body) ? body : Array.isArray(body.events) ? body.events : [body];

    if (events.length === 0) {
      return c.json({ success: false, error: 'Không có event nào được truyền lên.' }, 400);
    }

    const updatedCardIds = new Set<string>();

    for (const evt of events) {
      const reviewId = evt.review_id || crypto.randomUUID();
      const cardId = evt.card_id;
      const rating = evt.rating;
      const clientTime = evt.client_time || new Date().toISOString();
      const deviceId = evt.device_id || 'unknown';

      if (!cardId || !rating || rating < 1 || rating > 4) {
        continue;
      }

      // 1. Idempotently insert into review_logs using INSERT OR IGNORE
      await db
        .prepare(
          `INSERT OR IGNORE INTO review_logs (review_id, uid, card_id, rating, client_time, server_time, device_id, is_undone)
           VALUES (?, ?, ?, ?, ?, datetime('now'), ?, 0)`
        )
        .bind(reviewId, uid, cardId, rating, clientTime, deviceId)
        .run();

      updatedCardIds.add(cardId);
    }

    // 2. Recalculate deterministic SM-2 state for each affected card from its review log timeline
    const updatedCardsMap: Record<string, any> = {};

    for (const cardId of updatedCardIds) {
      const logsResult = await db
        .prepare(
          `SELECT review_id, uid, card_id, rating, client_time, server_time, device_id, is_undone
           FROM review_logs
           WHERE uid = ? AND card_id = ? AND is_undone = 0
           ORDER BY server_time ASC, client_time ASC`
        )
        .bind(uid, cardId)
        .all<any>();

      const logs = logsResult.results || [];
      const sm2State = recalculateSM2FromEvents(logs);

      // Update flashcard row with recalculated state
      await db
        .prepare(
          `UPDATE flashcards
           SET interval = ?, ease_factor = ?, repetitions = ?, next_review = ?, updated_at = datetime('now')
           WHERE id = ? AND uid = ?`
        )
        .bind(
          sm2State.interval,
          sm2State.easeFactor,
          sm2State.repetitions,
          sm2State.nextReview,
          cardId,
          uid
        )
        .run();

      updatedCardsMap[cardId] = {
        card_id: cardId,
        ...sm2State
      };
    }

    return c.json({
      success: true,
      processed: events.length,
      updated_cards: updatedCardsMap
    });
  } catch (error) {
    console.error('Error processing review events:', error);
    return c.json({ success: false, error: 'Không thể xử lý review events.' }, 500);
  }
});

// POST /api/v1/flashcards/review-events/undo — Undo a review event
flashcards.post('/review-events/undo', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const body = await c.req.json<{ review_id: string; card_id?: string }>();
    const { review_id, card_id } = body;

    if (!review_id) {
      return c.json({ success: false, error: 'Missing review_id' }, 400);
    }

    // Mark review_id as undone
    await db
      .prepare(`UPDATE review_logs SET is_undone = 1 WHERE review_id = ? AND uid = ?`)
      .bind(review_id, uid)
      .run();

    // Determine card_id if not provided
    let targetCardId = card_id;
    if (!targetCardId) {
      const log = await db
        .prepare(`SELECT card_id FROM review_logs WHERE review_id = ? AND uid = ?`)
        .bind(review_id, uid)
        .first<{ card_id: string }>();
      targetCardId = log?.card_id;
    }

    let sm2State = null;
    if (targetCardId) {
      const logsResult = await db
        .prepare(
          `SELECT review_id, uid, card_id, rating, client_time, server_time, device_id, is_undone
           FROM review_logs
           WHERE uid = ? AND card_id = ? AND is_undone = 0
           ORDER BY server_time ASC, client_time ASC`
        )
        .bind(uid, targetCardId)
        .all<any>();

      sm2State = recalculateSM2FromEvents(logsResult.results || []);

      await db
        .prepare(
          `UPDATE flashcards
           SET interval = ?, ease_factor = ?, repetitions = ?, next_review = ?, updated_at = datetime('now')
           WHERE id = ? AND uid = ?`
        )
        .bind(
          sm2State.interval,
          sm2State.easeFactor,
          sm2State.repetitions,
          sm2State.nextReview,
          targetCardId,
          uid
        )
        .run();
    }

    return c.json({
      success: true,
      card_id: targetCardId,
      updated_state: sm2State
    });
  } catch (error) {
    console.error('Error undoing review event:', error);
    return c.json({ success: false, error: 'Không thể hoàn tác review event.' }, 500);
  }
});

export default flashcards;

