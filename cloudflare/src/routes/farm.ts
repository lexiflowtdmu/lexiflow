// ============================================================
// Farm Routes — /api/v1/farm/*
// Hay Day-style farming: plant → water with vocab study → harvest → fulfill orders → earn coins
// ============================================================

import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse } from '../types/index.js';

export const farmRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// ─── Crop Catalog ─────────────────────────────────────────────────────────────
export interface CropDef {
  name: string;
  emoji: string;
  words_needed: number; // water drops to reach each stage (x2 total: seed→grow→ready)
  base_price: number;   // coins per unit when sold in an order
}

export const CROP_CATALOG: Record<string, CropDef> = {
  corn:       { name: 'Corn',       emoji: '🌽', words_needed: 5,  base_price: 10 },
  tomato:     { name: 'Tomato',     emoji: '🍅', words_needed: 8,  base_price: 15 },
  flower:     { name: 'Flower',     emoji: '🌸', words_needed: 6,  base_price: 12 },
  apple:      { name: 'Apple',      emoji: '🍎', words_needed: 10, base_price: 20 },
  herbs:      { name: 'Herbs',      emoji: '🌿', words_needed: 7,  base_price: 14 },
  blueberry:  { name: 'Blueberry',  emoji: '🫐', words_needed: 12, base_price: 25 },
};

const CROP_KEYS = Object.keys(CROP_CATALOG);

// ─── Types ────────────────────────────────────────────────────────────────────
interface FarmPlot {
  id: string;
  uid: string;
  slot_index: number;
  crop_type: string | null;
  planted_at: string | null;
  words_needed: number;
  words_progress: number;
  stage: number; // 0=empty, 1=growing, 2=ready
}

interface FarmInventoryRow {
  uid: string;
  item_type: string;
  quantity: number;
}

interface FarmOrder {
  id: string;
  uid: string;
  items_json: string;
  reward_coins: number;
  reward_xp: number;
  expires_at: string;
  status: string;
  created_at: string;
}

interface OrderItem { type: string; qty: number }

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Ensure user has 8 farm plot rows; create missing ones. */
async function ensurePlots(db: D1Database, uid: string): Promise<void> {
  const existing = await db
    .prepare('SELECT slot_index FROM farm_plots WHERE uid = ?')
    .bind(uid)
    .all<{ slot_index: number }>();

  const existingSlots = new Set((existing.results || []).map((r) => r.slot_index));
  const missing = [];
  for (let i = 0; i < 8; i++) {
    if (!existingSlots.has(i)) {
      missing.push(
        db.prepare(
          `INSERT INTO farm_plots (id, uid, slot_index, crop_type, planted_at, words_needed, words_progress, stage)
           VALUES (?, ?, ?, NULL, NULL, 5, 0, 0)`
        ).bind(`plot-${uid}-${i}`, uid, i)
      );
    }
  }
  if (missing.length > 0) await db.batch(missing);
}

/** Ensure user has a pet/wallet row; create with defaults if missing. */
async function ensurePet(db: D1Database, uid: string): Promise<void> {
  const pet = await db.prepare('SELECT uid FROM user_pets WHERE uid = ?').bind(uid).first();
  if (!pet) {
    await db
      .prepare(
        `INSERT INTO user_pets (uid, pet_type, pet_name, hunger, happiness, coins, last_fed_at, last_played_at)
         VALUES (?, 'cat', 'Mochi', 100, 100, 50, datetime('now'), datetime('now'))`
      )
      .bind(uid)
      .run();
  }
}

/** Generate up to `needed` new orders for a user, up to 3 total active. */
async function generateOrders(db: D1Database, uid: string, needed: number): Promise<FarmOrder[]> {
  const now = Date.now();
  const expiresAt = new Date(now + 4 * 60 * 60 * 1000).toISOString();
  const createdAt = new Date(now).toISOString();

  const generated: FarmOrder[] = [];
  const inserts = [];

  for (let n = 0; n < needed; n++) {
    const shuffled = [...CROP_KEYS].sort(() => Math.random() - 0.5);
    const picked = shuffled.slice(0, Math.random() < 0.5 ? 2 : 3);
    const items: OrderItem[] = picked.map((type) => ({
      type,
      qty: Math.floor(Math.random() * 3) + 1,
    }));
    const rewardCoins =
      Math.round(
        (items.reduce((sum, it) => sum + it.qty * (CROP_CATALOG[it.type]?.base_price ?? 10), 0) * 1.5) / 5
      ) * 5;
    const rewardXp = Math.round(rewardCoins / 3);
    const orderId = `order-${now}-${n}-${Math.random().toString(36).substr(2, 4)}`;
    const itemsJson = JSON.stringify(items);

    inserts.push(
      db
        .prepare(
          `INSERT INTO farm_orders (id, uid, items_json, reward_coins, reward_xp, expires_at, status)
           VALUES (?, ?, ?, ?, ?, ?, 'active')`
        )
        .bind(orderId, uid, itemsJson, rewardCoins, rewardXp, expiresAt)
    );
    generated.push({
      id: orderId, uid, items_json: itemsJson,
      reward_coins: rewardCoins, reward_xp: rewardXp,
      expires_at: expiresAt, status: 'active', created_at: createdAt,
    });
  }

  if (inserts.length > 0) await db.batch(inserts);
  return generated;
}

// ─── Routes ───────────────────────────────────────────────────────────────────

/**
 * GET /api/v1/farm/state
 * Full farm snapshot: plots + inventory + active orders
 */
farmRoutes.get('/state', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  await ensurePlots(db, uid);
  await ensurePet(db, uid);

  const [plotsRes, inventoryRes, petRow] = await Promise.all([
    db.prepare('SELECT * FROM farm_plots WHERE uid = ? ORDER BY slot_index ASC').bind(uid).all<FarmPlot>(),
    db.prepare('SELECT * FROM farm_inventory WHERE uid = ?').bind(uid).all<FarmInventoryRow>(),
    db.prepare('SELECT * FROM user_pets WHERE uid = ?').bind(uid).first<any>(),
  ]);

  // Mark expired orders
  await db
    .prepare(`UPDATE farm_orders SET status = 'expired' WHERE uid = ? AND status = 'active' AND expires_at < datetime('now')`)
    .bind(uid)
    .run();

  const ordersRes = await db
    .prepare(`SELECT * FROM farm_orders WHERE uid = ? AND status = 'active' ORDER BY created_at ASC`)
    .bind(uid)
    .all<FarmOrder>();

  // Auto-generate orders to fill up to 3 slots
  let orders = ordersRes.results || [];
  if (orders.length < 3) {
    const newOrders = await generateOrders(db, uid, 3 - orders.length);
    orders = [...orders, ...newOrders];
  }

  const inventory: Record<string, number> = {};
  for (const row of inventoryRes.results || []) {
    inventory[row.item_type] = row.quantity;
  }

  return c.json<ApiResponse<{
    plots: FarmPlot[];
    inventory: Record<string, number>;
    orders: Array<FarmOrder & { items: OrderItem[] }>;
    coins: number;
    crop_catalog: typeof CROP_CATALOG;
  }>>({
    success: true,
    data: {
      plots: plotsRes.results || [],
      inventory,
      orders: orders.map((o) => ({ ...o, items: JSON.parse(o.items_json) })),
      coins: petRow?.coins ?? 0,
      crop_catalog: CROP_CATALOG,
    }
  });
});

/**
 * POST /api/v1/farm/plant
 * Plant a crop in a given slot  { slot_index, crop_type }
 */
farmRoutes.post('/plant', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ slot_index: number; crop_type: string }>();

  if (body.slot_index < 0 || body.slot_index > 7) {
    return c.json<ApiResponse>({ success: false, error: 'slot_index phải từ 0–7' }, 400);
  }
  if (!CROP_CATALOG[body.crop_type]) {
    return c.json<ApiResponse>({ success: false, error: `Loại cây không hợp lệ: ${body.crop_type}` }, 400);
  }

  await ensurePlots(db, uid);

  const plot = await db
    .prepare('SELECT * FROM farm_plots WHERE uid = ? AND slot_index = ?')
    .bind(uid, body.slot_index)
    .first<FarmPlot>();

  if (!plot) return c.json<ApiResponse>({ success: false, error: 'Ô đất không tồn tại' }, 404);
  if (plot.stage !== 0 || plot.crop_type !== null) {
    return c.json<ApiResponse>({ success: false, error: 'Ô đất này đang có cây. Thu hoạch trước.' }, 400);
  }

  const cropDef = CROP_CATALOG[body.crop_type];
  await db
    .prepare(
      `UPDATE farm_plots
       SET crop_type = ?, planted_at = datetime('now'), words_needed = ?, words_progress = 0, stage = 1
       WHERE uid = ? AND slot_index = ?`
    )
    .bind(body.crop_type, cropDef.words_needed, uid, body.slot_index)
    .run();

  return c.json<ApiResponse>({ success: true });
});

/**
 * POST /api/v1/farm/water
 * Apply water drops (vocab words studied) to the first growing plot  { drops }
 * Called by Flutter after each study session.
 */
farmRoutes.post('/water', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ drops: number }>();

  const drops = Math.min(Math.max(body.drops ?? 1, 1), 50); // clamp 1–50

  // Find first active (growing) plot — prioritise plots closest to ready
  const plot = await db
    .prepare(
      `SELECT * FROM farm_plots
       WHERE uid = ? AND stage = 1
       ORDER BY (words_needed - words_progress) ASC
       LIMIT 1`
    )
    .bind(uid)
    .first<FarmPlot>();

  if (!plot) {
    return c.json<ApiResponse>({ success: true, message: 'Không có cây nào đang trồng. Hãy trồng cây trước!' });
  }

  const newProgress = plot.words_progress + drops;
  const isReady = newProgress >= plot.words_needed;

  await db
    .prepare(
      `UPDATE farm_plots
       SET words_progress = ?, stage = ?
       WHERE id = ? AND uid = ?`
    )
    .bind(Math.min(newProgress, plot.words_needed), isReady ? 2 : 1, plot.id, uid)
    .run();

  return c.json<ApiResponse<{ plot_id: string; progress: number; needed: number; is_ready: boolean }>>({
    success: true,
    data: {
      plot_id: plot.id,
      progress: Math.min(newProgress, plot.words_needed),
      needed: plot.words_needed,
      is_ready: isReady,
    }
  });
});

/**
 * POST /api/v1/farm/harvest
 * Harvest a ready plot, add to inventory  { plot_id }
 */
farmRoutes.post('/harvest', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ plot_id: string }>();

  const plot = await db
    .prepare('SELECT * FROM farm_plots WHERE id = ? AND uid = ?')
    .bind(body.plot_id, uid)
    .first<FarmPlot>();

  if (!plot) return c.json<ApiResponse>({ success: false, error: 'Ô đất không tồn tại' }, 404);
  if (plot.stage !== 2) return c.json<ApiResponse>({ success: false, error: 'Cây chưa đến lúc thu hoạch' }, 400);

  const cropType = plot.crop_type!;
  const harvestAmount = Math.floor(Math.random() * 2) + 2; // 2–3 units per harvest

  await db.batch([
    // Reset plot to empty
    db.prepare(
      `UPDATE farm_plots
       SET crop_type = NULL, planted_at = NULL, words_needed = 5, words_progress = 0, stage = 0
       WHERE id = ? AND uid = ?`
    ).bind(plot.id, uid),
    // Add to inventory
    db.prepare(
      `INSERT INTO farm_inventory (uid, item_type, quantity) VALUES (?, ?, ?)
       ON CONFLICT(uid, item_type) DO UPDATE SET quantity = quantity + ?`
    ).bind(uid, cropType, harvestAmount, harvestAmount),
  ]);

  return c.json<ApiResponse<{ crop_type: string; amount: number }>>({
    success: true,
    data: { crop_type: cropType, amount: harvestAmount }
  });
});

/**
 * GET /api/v1/farm/orders
 * Get active orders (auto-generates new ones to fill up to 3 slots)
 */
farmRoutes.get('/orders', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  // Expire stale orders
  await db
    .prepare(`UPDATE farm_orders SET status = 'expired' WHERE uid = ? AND status = 'active' AND expires_at < datetime('now')`)
    .bind(uid)
    .run();

  const active = await db
    .prepare(`SELECT * FROM farm_orders WHERE uid = ? AND status = 'active' ORDER BY created_at ASC`)
    .bind(uid)
    .all<FarmOrder>();

  let orders = active.results || [];
  if (orders.length < 3) {
    const newOrders = await generateOrders(db, uid, 3 - orders.length);
    orders = [...orders, ...newOrders];
  }

  return c.json<ApiResponse<Array<FarmOrder & { items: OrderItem[] }>>>({
    success: true,
    data: orders.map((o) => ({ ...o, items: JSON.parse(o.items_json) }))
  });
});

/**
 * POST /api/v1/farm/orders/:id/fulfill
 * Fulfill an order — deducts inventory items, grants coins + XP
 */
farmRoutes.post('/orders/:id/fulfill', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const orderId = c.req.param('id');

  const order = await db
    .prepare(`SELECT * FROM farm_orders WHERE id = ? AND uid = ? AND status = 'active'`)
    .bind(orderId, uid)
    .first<FarmOrder>();

  if (!order) return c.json<ApiResponse>({ success: false, error: 'Đơn hàng không tồn tại hoặc đã hết hạn' }, 404);

  const items: OrderItem[] = JSON.parse(order.items_json);

  // Verify inventory sufficiency — batch read instead of N+1
  const invResults = await db.batch<{ quantity: number }>(
    items.map((item) =>
      db.prepare('SELECT quantity FROM farm_inventory WHERE uid = ? AND item_type = ?').bind(uid, item.type)
    )
  );
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const qty = invResults[i].results?.[0]?.quantity ?? 0;
    if (qty < item.qty) {
      return c.json<ApiResponse>({
        success: false,
        error: `Không đủ ${CROP_CATALOG[item.type]?.name ?? item.type} (cần ${item.qty}, có ${qty})`
      }, 400);
    }
  }

  // Deduct inventory + mark order fulfilled + credit coins + XP in batch
  const deductStmts = items.map((item) =>
    db.prepare('UPDATE farm_inventory SET quantity = quantity - ? WHERE uid = ? AND item_type = ?')
      .bind(item.qty, uid, item.type)
  );

  await db.batch([
    ...deductStmts,
    db.prepare(`UPDATE farm_orders SET status = 'fulfilled' WHERE id = ?`).bind(orderId),
    db.prepare(`UPDATE user_pets SET coins = coins + ?, updated_at = datetime('now') WHERE uid = ?`)
      .bind(order.reward_coins, uid),
    db.prepare(
      `INSERT INTO xp_transactions (id, uid, xp_amount, source, created_at)
       VALUES (?, ?, ?, 'farm_order', datetime('now'))`
    ).bind(`xp-farm-${Date.now()}`, uid, order.reward_xp),
    db.prepare(`UPDATE users SET xp = xp + ?, updated_at = datetime('now') WHERE uid = ?`)
      .bind(order.reward_xp, uid),
  ]);

  return c.json<ApiResponse<{ coins_earned: number; xp_earned: number }>>({
    success: true,
    data: { coins_earned: order.reward_coins, xp_earned: order.reward_xp }
  });
});

/**
 * POST /api/v1/farm/orders/:id/skip
 * Skip an order and generate a replacement (costs nothing for now — add skip tokens later)
 */
farmRoutes.post('/orders/:id/skip', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const orderId = c.req.param('id');

  const order = await db
    .prepare(`SELECT * FROM farm_orders WHERE id = ? AND uid = ? AND status = 'active'`)
    .bind(orderId, uid)
    .first<FarmOrder>();

  if (!order) return c.json<ApiResponse>({ success: false, error: 'Đơn hàng không tồn tại' }, 404);

  await db
    .prepare(`UPDATE farm_orders SET status = 'expired' WHERE id = ?`)
    .bind(orderId)
    .run();

  const [newOrder] = await generateOrders(db, uid, 1);

  return c.json<ApiResponse<FarmOrder & { items: OrderItem[] }>>({
    success: true,
    data: { ...newOrder, items: JSON.parse(newOrder.items_json) }
  });
});
