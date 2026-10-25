// ============================================================
// Study Streak Routes — /api/v1/streak/*
// ============================================================

import { Hono } from 'hono';
import type { AuthContext, Bindings, Variables } from '../types';

const streak = new Hono<{ Bindings: Bindings; Variables: Variables }>();

/**
 * Helper: parse date string to "YYYY-MM-DD" format for comparison.
 */
function toDateString(dateStr: string): string {
  try {
    const d = new Date(dateStr);
    // Check if date is valid
    if (isNaN(d.getTime())) {
      console.error('Invalid date:', dateStr);
      return todayString(); // fallback to today
    }
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  } catch (error) {
    console.error('Date parsing error:', error, dateStr);
    return todayString(); // fallback to today
  }
}

function todayString(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

function yesterdayString(): string {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, '0')}-${String(yesterday.getDate()).padStart(2, '0')}`;
}

// GET /api/v1/streak — Lấy streak hiện tại của user
streak.get('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const result = await db
      .prepare('SELECT * FROM study_streaks WHERE uid = ?')
      .bind(uid)
      .first();

    if (!result) {
      return c.json({ success: true, streak: 0 });
    }

    const row = result as { current_streak: number; longest_streak: number; last_study_date: string };
    const lastDate = toDateString(row.last_study_date);
    const today = todayString();
    const yesterday = yesterdayString();

    if (lastDate === today || lastDate === yesterday) {
      return c.json({ success: true, streak: row.current_streak, longest_streak: row.longest_streak ?? row.current_streak });
    } else {
      return c.json({ success: true, streak: 0, longest_streak: row.longest_streak ?? 0 });
    }
  } catch (error) {
    console.error('Error fetching streak:', error);
    return c.json({ success: false, error: 'Không thể tải streak.' }, 500);
  }
});

// POST /api/v1/streak — Cập nhật streak (ghi nhận học tập hôm nay)
streak.post('/', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  try {
    const today = todayString();
    const result = await db
      .prepare('SELECT * FROM study_streaks WHERE uid = ?')
      .bind(uid)
      .first();

    if (!result) {
      // First time studying — create new streak record
      await db
        .prepare(
          `INSERT INTO study_streaks (uid, current_streak, longest_streak, last_study_date)
           VALUES (?, 1, 1, ?)`
        )
        .bind(uid, today)
        .run();

      return c.json({ success: true, streak: 1, updated: true });
    }

    const row = result as {
      current_streak: number;
      longest_streak: number;
      last_study_date: string;
    };
    const lastDate = toDateString(row.last_study_date);
    const yesterday = yesterdayString();

    if (lastDate === today) {
      // Already studied today — no update needed
      return c.json({ success: true, streak: row.current_streak, updated: false });
    }

    if (lastDate === yesterday) {
      // Consecutive day — streak continues
      const newStreak = row.current_streak + 1;
      const newLongest = newStreak > row.longest_streak ? newStreak : row.longest_streak;

      await db
        .prepare(
          `UPDATE study_streaks
           SET current_streak = ?, longest_streak = ?, last_study_date = ?
           WHERE uid = ?`
        )
        .bind(newStreak, newLongest, today, uid)
        .run();

      return c.json({ success: true, streak: newStreak, updated: true });
    }

    // Streak broken — reset to 1
    await db
      .prepare(
        `UPDATE study_streaks
         SET current_streak = 1, last_study_date = ?
         WHERE uid = ?`
      )
      .bind(today, uid)
      .run();

    return c.json({ success: true, streak: 1, updated: true });
  } catch (error) {
    console.error('Error updating streak:', error);
    return c.json({ success: false, error: 'Không thể cập nhật streak.' }, 500);
  }
});

export default streak;
