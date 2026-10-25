import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse } from '../types/index.js';

export const deckRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function generateDeckCode(): string {
  const randomNum = Math.floor(1000 + Math.random() * 9000);
  return `DECK-${randomNum}`;
}

export interface SharedDeckItem {
  id: string;
  owner_uid: string;
  owner_name?: string;
  title: string;
  description: string;
  words_json: string;
  share_code: string;
  created_at: string;
}

async function fetchSharedDeck(c: any, shareCode: string): Promise<{ deck: SharedDeckItem | null, errorResponse?: any }> {
  if (!shareCode) {
    return { deck: null, errorResponse: c.json({ success: false, error: 'Missing shareCode' }, 400) };
  }

  const db = c.env.DB;
  const deck = (await db.prepare('SELECT * FROM shared_decks WHERE share_code = ?').bind(shareCode.trim().toUpperCase()).first()) as SharedDeckItem | null;

  if (!deck) {
    return { deck: null, errorResponse: c.json({ success: false, error: 'Bộ thẻ chia sẻ không tồn tại' }, 404) };
  }

  return { deck };
}

/**
 * POST /api/decks/share
 * Share a flashcard deck & generate a share code / link
 */
deckRoutes.post('/share', async (c) => {
  try {
    const { uid: ownerUid } = c.get('auth');
    const body = await c.req.json<{
      title: string;
      description?: string;
      words: Array<{ word: string; meaning: string; example?: string }>;
    }>();

    if (!body.title || !body.words || body.words.length === 0) {
      return c.json<ApiResponse>({ success: false, error: 'Missing title or words array' }, 400);
    }

    const db = c.env.DB;
    const deckId = `deck-${Date.now()}`;
    const shareCode = generateDeckCode();
    const wordsJson = JSON.stringify(body.words);

    await db
      .prepare(
        `INSERT INTO shared_decks (id, owner_uid, title, description, words_json, share_code, created_at)
         VALUES (?, ?, ?, ?, ?, ?, datetime('now'))`
      )
      .bind(deckId, ownerUid, body.title, body.description || '', wordsJson, shareCode)
      .run();

    return c.json<ApiResponse<{ deckId: string; shareCode: string; shareUrl: string }>>({
      success: true,
      data: {
        deckId,
        shareCode,
        shareUrl: `https://lexiflow.app/deck/${shareCode}`
      }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/decks/preview/:shareCode
 * Preview shared deck content (Read-Only)
 */
deckRoutes.get('/preview/:shareCode', async (c) => {
  try {
    const shareCode = c.req.param('shareCode').trim().toUpperCase();
    const db = c.env.DB;

    const deck = await db
      .prepare(
        `SELECT d.*, u.display_name as owner_name 
         FROM shared_decks d
         LEFT JOIN users u ON u.uid = d.owner_uid
         WHERE d.share_code = ?`
      )
      .bind(shareCode)
      .first<SharedDeckItem>();

    if (!deck) {
      return c.json<ApiResponse>({ success: false, error: 'Bộ thẻ chia sẻ không tồn tại hoặc đã bị xóa' }, 404);
    }

    const words = JSON.parse(deck.words_json);

    return c.json<ApiResponse<{ deck: SharedDeckItem; words: any[] }>>({
      success: true,
      data: { deck, words }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * POST /api/decks/import
 * Import shared deck into recipient user's flashcards as a copy
 */
deckRoutes.post('/import', async (c) => {
  try {
    const { uid: targetUid } = c.get('auth');
    const body = await c.req.json<{ shareCode: string }>();
    const { deck, errorResponse } = await fetchSharedDeck(c, body.shareCode);
    if (errorResponse) return errorResponse;

    const db = c.env.DB;
    const words: Array<{ word: string; meaning: string; example?: string }> = JSON.parse(deck!.words_json);

    const insertStmts = words.map((item) => {
      const cardId = `fc-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;
      return db
        .prepare(
          `INSERT OR IGNORE INTO flashcards (id, uid, word, meaning, example, interval, ease_factor, repetitions, next_review, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, 0, 2.5, 0, datetime('now'), datetime('now'), datetime('now'))`
        )
        .bind(cardId, targetUid, item.word, item.meaning || '', item.example || '');
    });

    if (insertStmts.length > 0) {
      await db.batch(insertStmts);
    }

    // Track user import in user_imported_decks
    await db
      .prepare(
        `INSERT INTO user_imported_decks (uid, share_code, imported_count, last_synced_at)
         VALUES (?, ?, ?, datetime('now'))
         ON CONFLICT(uid, share_code) DO UPDATE SET
           imported_count = excluded.imported_count,
           last_synced_at = datetime('now')`
      )
      .bind(targetUid, deck!.share_code, words.length)
      .run();

    return c.json<ApiResponse<{ importedCount: number; title: string }>>({
      success: true,
      data: { importedCount: words.length, title: deck!.title }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/decks/check-updates?shareCode=...&targetUid=...
 * Check if shared deck owner has added new words since recipient last imported
 */
deckRoutes.get('/check-updates', async (c) => {
  try {
    const { uid: targetUid } = c.get('auth');
    const shareCode = c.req.query('shareCode')?.trim().toUpperCase();

    if (!shareCode) {
      return c.json<ApiResponse>({ success: false, error: 'Missing shareCode' }, 400);
    }

    const db = c.env.DB;
    const deck = await db.prepare('SELECT * FROM shared_decks WHERE share_code = ?').bind(shareCode).first<SharedDeckItem>();

    if (!deck) {
      return c.json<ApiResponse>({ success: false, error: 'Shared deck not found' }, 404);
    }

    const words: Array<{ word: string }> = JSON.parse(deck.words_json);

    // Get user's existing cards
    const userCards = await db
      .prepare('SELECT word FROM flashcards WHERE uid = ?')
      .bind(targetUid)
      .all<{ word: string }>();

    const existingSet = new Set((userCards.results || []).map((c) => c.word.toLowerCase()));
    const newWords = words.filter((w) => !existingSet.has(w.word.toLowerCase()));

    return c.json<ApiResponse<{ newWordsCount: number; totalWords: number; title: string }>>({
      success: true,
      data: {
        newWordsCount: newWords.length,
        totalWords: words.length,
        title: deck.title
      }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * POST /api/decks/sync-new-words
 * Import ONLY newly added words into recipient's flashcards without overwriting SM-2 progress on old words
 */
deckRoutes.post('/sync-new-words', async (c) => {
  try {
    const { uid: targetUid } = c.get('auth');
    const body = await c.req.json<{ shareCode: string }>();
    const { deck, errorResponse } = await fetchSharedDeck(c, body.shareCode);
    if (errorResponse) return errorResponse;

    const db = c.env.DB;
    const words: Array<{ word: string; meaning: string; example?: string }> = JSON.parse(deck!.words_json);

    // Get user's existing cards
    const userCards = await db
      .prepare('SELECT word FROM flashcards WHERE uid = ?')
      .bind(targetUid)
      .all<{ word: string }>();

    const existingSet = new Set((userCards.results || []).map((row) => row.word.toLowerCase()));
    const newWords = words.filter((w) => !existingSet.has(w.word.toLowerCase()));

    if (newWords.length > 0) {
      const insertStmts = newWords.map((item) => {
        const cardId = `fc-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;
        return db
          .prepare(
            `INSERT OR IGNORE INTO flashcards (id, uid, word, meaning, example, interval, ease_factor, repetitions, next_review, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, 0, 2.5, 0, datetime('now'), datetime('now'), datetime('now'))`
          )
          .bind(cardId, targetUid, item.word, item.meaning || '', item.example || '');
      });
      await db.batch(insertStmts);
    }

    // Update tracking
    await db
      .prepare(
        `INSERT INTO user_imported_decks (uid, share_code, imported_count, last_synced_at)
         VALUES (?, ?, ?, datetime('now'))
         ON CONFLICT(uid, share_code) DO UPDATE SET
           imported_count = excluded.imported_count,
           last_synced_at = datetime('now')`
      )
      .bind(targetUid, deck!.share_code, words.length)
      .run();

    return c.json<ApiResponse<{ newlyAddedCount: number; title: string }>>({
      success: true,
      data: { newlyAddedCount: newWords.length, title: deck!.title }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/decks/summary
 * Single-query aggregated deck summary with due counts using index covered scan
 * Eliminates N+1 query overhead and full table COUNT(*) scans
 */
deckRoutes.get('/summary', async (c) => {
  const startTime = Date.now();
  try {
    const { uid } = c.get('auth');

    const db = c.env.DB;

    // Single covered aggregation query across user cards and imported decks
    const summaryQuery = await db
      .prepare(
        `SELECT 
           COUNT(*) as total_cards,
           SUM(CASE WHEN next_review <= datetime('now') THEN 1 ELSE 0 END) as due_cards,
           SUM(CASE WHEN repetitions = 0 THEN 1 ELSE 0 END) as new_cards,
           SUM(CASE WHEN repetitions > 0 AND next_review > datetime('now') THEN 1 ELSE 0 END) as learning_cards
         FROM flashcards
         WHERE uid = ?`
      )
      .bind(uid)
      .first<{ total_cards: number; due_cards: number; new_cards: number; learning_cards: number }>();

    const durationMs = Date.now() - startTime;
    c.header('X-Response-Time', `${durationMs}ms`);

    return c.json<ApiResponse<{
      summary: {
        totalCards: number;
        dueCards: number;
        newCards: number;
        learningCards: number;
      };
      executionTimeMs: number;
    }>>({
      success: true,
      data: {
        summary: {
          totalCards: summaryQuery?.total_cards || 0,
          dueCards: summaryQuery?.due_cards || 0,
          newCards: summaryQuery?.new_cards || 0,
          learningCards: summaryQuery?.learning_cards || 0,
        },
        executionTimeMs: durationMs
      }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

