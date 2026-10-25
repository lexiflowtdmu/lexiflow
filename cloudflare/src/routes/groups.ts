import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse, FriendUser } from '../types/index.js';

export const groupRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function generateGroupCode(): string {
  const randomNum = Math.floor(1000 + Math.random() * 9000);
  return `GRP-${randomNum}`;
}

export interface GroupItem {
  id: string;
  name: string;
  description: string;
  created_by_uid: string;
  invite_code: string;
  member_count?: number;
  created_at: string;
}

/**
 * POST /api/groups
 * Create a new private group
 */
groupRoutes.post('/', async (c) => {
  try {
    const { uid } = c.get('auth'); // Always use JWT uid, never trust body.createdByUid
    const body = await c.req.json<{
      name: string;
      description?: string;
    }>();

    if (!body.name) {
      return c.json<ApiResponse>({ success: false, error: 'Missing name' }, 400);
    }

    const db = c.env.DB;
    const groupId = `grp-${Date.now()}`;
    const inviteCode = generateGroupCode();

    await db
      .prepare(
        `INSERT INTO groups (id, name, description, created_by_uid, invite_code, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))`
      )
      .bind(groupId, body.name, body.description || '', uid, inviteCode)
      .run();

    // Add owner as first member
    await db
      .prepare(
        `INSERT INTO group_members (group_id, uid, role, joined_at)
         VALUES (?, ?, 'owner', datetime('now'))`
      )
      .bind(groupId, uid)
      .run();

    return c.json<ApiResponse<{ id: string; inviteCode: string }>>({
      success: true,
      data: { id: groupId, inviteCode }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * POST /api/groups/join
 * Join group using invite_code
 */
groupRoutes.post('/join', async (c) => {
  try {
    const { uid } = c.get('auth'); // Always use JWT uid, never trust body.uid
    const body = await c.req.json<{ inviteCode: string }>();

    if (!body.inviteCode) {
      return c.json<ApiResponse>({ success: false, error: 'Missing inviteCode' }, 400);
    }

    const db = c.env.DB;
    const group = await db.prepare('SELECT * FROM groups WHERE invite_code = ?').bind(body.inviteCode.trim()).first<GroupItem>();

    if (!group) {
      return c.json<ApiResponse>({ success: false, error: 'Mã nhóm không tồn tại' }, 404);
    }

    await db
      .prepare(
        `INSERT INTO group_members (group_id, uid, role, joined_at)
         VALUES (?, ?, 'member', datetime('now'))
         ON CONFLICT(group_id, uid) DO NOTHING`
      )
      .bind(group.id, uid)
      .run();

    return c.json<ApiResponse<{ group: GroupItem }>>({
      success: true,
      data: { group }
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

/**
 * GET /api/groups/my-groups?uid=...
 * Get list of groups current user belongs to
 */
groupRoutes.get('/my-groups', async (c) => {
  try {
    const { uid } = c.get('auth'); // Always use JWT uid, never trust query param

    const db = c.env.DB;
    const res = await db
      .prepare(
        `SELECT g.*, (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count
         FROM groups g
         JOIN group_members gm ON g.id = gm.group_id
         WHERE gm.uid = ?`
      )
      .bind(uid)
      .all<GroupItem>();

    return c.json<ApiResponse<GroupItem[]>>({
      success: true,
      data: res.results
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});

function getStartOfWeekISO(): string {
  const now = new Date();
  const day = now.getUTCDay(); // 0 is Sunday, 1 is Monday
  const diffToMonday = day === 0 ? -6 : 1 - day;
  const monday = new Date(now);
  monday.setUTCDate(now.getUTCDate() + diffToMonday);
  monday.setUTCHours(0, 0, 0, 0);
  return monday.toISOString().replace('T', ' ').substring(0, 19);
}

/**
 * GET /api/groups/:groupId/leaderboard?period=weekly|all
 * Private group leaderboard sorted by XP (weekly or lifetime total) and streak
 */
groupRoutes.get('/:groupId/leaderboard', async (c) => {
  try {
    const { uid } = c.get('auth');
    const groupId = c.req.param('groupId');
    const period = c.req.query('period') || 'all';
    const db = c.env.DB;

    // Membership check — prevent leaking private group data to outsiders
    const isMember = await db
      .prepare('SELECT 1 FROM group_members WHERE group_id = ? AND uid = ?')
      .bind(groupId, uid)
      .first();
    if (!isMember) {
      return c.json<ApiResponse>({ success: false, error: 'Bạn không phải thành viên của nhóm này' }, 403);
    }

    if (period === 'weekly') {
      const startOfWeek = getStartOfWeekISO();
      const membersRes = await db
        .prepare(
          `SELECT u.*, 
                  s.current_streak, 
                  gm.role,
                  COALESCE((
                    SELECT SUM(xp_amount) 
                    FROM xp_transactions 
                    WHERE uid = u.uid AND created_at >= ?
                  ), 0) as weekly_xp
           FROM group_members gm
           JOIN users u ON u.uid = gm.uid
           LEFT JOIN study_streaks s ON u.uid = s.uid
           WHERE gm.group_id = ?
           ORDER BY weekly_xp DESC, s.current_streak DESC`
        )
        .bind(startOfWeek, groupId)
        .all<FriendUser & { role: string; weekly_xp?: number }>();

      return c.json<ApiResponse<(FriendUser & { role: string; weekly_xp?: number })[]>>({
        success: true,
        data: membersRes.results
      });
    }

    // Default 'all' period: sorted by lifetime total XP
    const membersRes = await db
      .prepare(
        `SELECT u.*, s.current_streak, gm.role
         FROM group_members gm
         JOIN users u ON u.uid = gm.uid
         LEFT JOIN study_streaks s ON u.uid = s.uid
         WHERE gm.group_id = ?
         ORDER BY u.xp DESC, s.current_streak DESC`
      )
      .bind(groupId)
      .all<FriendUser & { role: string }>();

    return c.json<ApiResponse<(FriendUser & { role: string })[]>>({
      success: true,
      data: membersRes.results
    });
  } catch (err) {
    return c.json<ApiResponse>({ success: false, error: (err as Error).message }, 500);
  }
});
