// ============================================================
// Home Routes — /api/v1/home/*
// Adorable Home-style pet care + room decoration with mini-game coins
// ============================================================

import { Hono } from 'hono';
import type { Bindings, Variables, ApiResponse } from '../types/index.js';

export const homeRoutes = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// ─── Shop Catalog (static, no DB needed) ─────────────────────────────────────
export interface ShopItem {
  id: string;
  name: string;
  emoji: string;
  price: number;
  category: 'pet_food' | 'pet_toy' | 'furniture';
  hunger_restore?: number;    // for pet_food
  happiness_restore?: number; // for pet_toy
  description: string;
}

export const SHOP_CATALOG: ShopItem[] = [
  // Pet food
  { id: 'food_basic',   name: 'Cơm Cá',       emoji: '🐟', price: 30,  category: 'pet_food',  hunger_restore: 30,  description: 'Bổ sung dinh dưỡng cơ bản cho pet' },
  { id: 'food_premium', name: 'Sushi Sang',    emoji: '🍣', price: 80,  category: 'pet_food',  hunger_restore: 70,  description: 'Bữa ăn cao cấp, pet cực kỳ vui' },
  { id: 'food_milk',    name: 'Ly Sữa',        emoji: '🥛', price: 20,  category: 'pet_food',  hunger_restore: 20,  description: 'Nhẹ nhàng, tốt cho sức khỏe' },
  // Pet toys
  { id: 'toy_ball',     name: 'Bóng Len',      emoji: '🧶', price: 50,  category: 'pet_toy',   happiness_restore: 35, description: 'Chơi cùng pet cho niềm vui' },
  { id: 'toy_feather',  name: 'Que Lông Vũ',   emoji: '🪶', price: 40,  category: 'pet_toy',   happiness_restore: 25, description: 'Pet thích nhất' },
  // Furniture
  { id: 'sofa_basic',   name: 'Ghế Sofa',      emoji: '🛋️', price: 150, category: 'furniture', description: 'Chỗ ngồi thoải mái cho pet nghỉ ngơi' },
  { id: 'bookshelf',    name: 'Kệ Sách',       emoji: '📚', price: 120, category: 'furniture', description: 'Lưu giữ kiến thức vocab đã học' },
  { id: 'plant_indoor', name: 'Cây Trong Nhà', emoji: '🪴', price: 80,  category: 'furniture', description: 'Thêm màu xanh cho không gian sống' },
  { id: 'lamp_reading', name: 'Đèn Đọc Sách',  emoji: '🪔', price: 60,  category: 'furniture', description: 'Ánh sáng ấm áp cho buổi học tối' },
  { id: 'desk_study',   name: 'Bàn Học',       emoji: '🪑', price: 200, category: 'furniture', description: 'Nơi học từ vựng tập trung nhất' },
  { id: 'rug_cozy',     name: 'Thảm Êm',       emoji: '🏔️', price: 90,  category: 'furniture', description: 'Pet nằm lên thảm rất thích' },
  { id: 'clock_wall',   name: 'Đồng Hồ Tường', emoji: '🕰️', price: 110, category: 'furniture', description: 'Nhắc nhở giờ học đều đặn' },
];

// ─── Pet hunger/happiness decay (calculated at read-time, no background job needed) ─
// Hunger: -20 per 8 hours | Happiness: -15 per 8 hours
const DECAY_INTERVAL_MS = 8 * 60 * 60 * 1000; // 8 hours
const HUNGER_DECAY_PER_INTERVAL = 20;
const HAPPINESS_DECAY_PER_INTERVAL = 15;

function calcDecayed(stored: number, decay: number, lastAt: string): number {
  const elapsed = Date.now() - new Date(lastAt).getTime();
  const intervals = Math.floor(elapsed / DECAY_INTERVAL_MS);
  return Math.max(0, stored - intervals * decay);
}

/** Pet XP bonus: 5% per 20 happiness (up to +25% at 100 happiness) */
export function petXpBonus(happiness: number): number {
  return Math.floor(happiness / 20) * 5;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
interface PetRow {
  uid: string; pet_type: string; pet_name: string;
  hunger: number; happiness: number; coins: number;
  last_fed_at: string; last_played_at: string;
  created_at: string; updated_at: string;
}

interface FurnitureRow { id: string; uid: string; item_id: string; room_slot: number; purchased_at: string }

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

// ─── Routes ───────────────────────────────────────────────────────────────────

/**
 * GET /api/v1/home/state
 * Pet status (with live-calculated decay) + furniture list + shop catalog + coins
 */
homeRoutes.get('/state', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;

  await ensurePet(db, uid);

  const [petRow, furnitureRes] = await Promise.all([
    db.prepare('SELECT * FROM user_pets WHERE uid = ?').bind(uid).first<PetRow>(),
    db.prepare('SELECT * FROM home_furniture WHERE uid = ? ORDER BY room_slot ASC').bind(uid).all<FurnitureRow>(),
  ]);

  // Apply time-based decay at read-time (no background job)
  const currentHunger    = calcDecayed(petRow!.hunger,    HUNGER_DECAY_PER_INTERVAL,    petRow!.last_fed_at);
  const currentHappiness = calcDecayed(petRow!.happiness, HAPPINESS_DECAY_PER_INTERVAL, petRow!.last_played_at);
  const xpBonus          = petXpBonus(currentHappiness);

  // Identify owned furniture item_ids for client lock/unlock display
  const ownedItemIds = (furnitureRes.results || []).map((f) => f.item_id);

  return c.json<ApiResponse<{
    pet: { type: string; name: string; hunger: number; happiness: number; xp_bonus_pct: number };
    coins: number;
    furniture: FurnitureRow[];
    owned_item_ids: string[];
    shop: ShopItem[];
  }>>({
    success: true,
    data: {
      pet: {
        type: petRow!.pet_type,
        name: petRow!.pet_name,
        hunger: currentHunger,
        happiness: currentHappiness,
        xp_bonus_pct: xpBonus,
      },
      coins: petRow!.coins,
      furniture: furnitureRes.results || [],
      owned_item_ids: ownedItemIds,
      shop: SHOP_CATALOG,
    }
  });
});

/**
 * POST /api/v1/home/pet/feed
 * Feed the pet — costs coins, restores hunger  { item_id }
 */
homeRoutes.post('/pet/feed', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ item_id: string }>();

  const item = SHOP_CATALOG.find((s) => s.id === body.item_id && s.category === 'pet_food');
  if (!item) return c.json<ApiResponse>({ success: false, error: 'Thức ăn không hợp lệ' }, 400);

  await ensurePet(db, uid);
  const petRow = await db.prepare('SELECT * FROM user_pets WHERE uid = ?').bind(uid).first<PetRow>();

  if (petRow!.coins < item.price) {
    return c.json<ApiResponse>({ success: false, error: `Không đủ coin (cần ${item.price}, có ${petRow!.coins})` }, 400);
  }

  const currentHunger = calcDecayed(petRow!.hunger, HUNGER_DECAY_PER_INTERVAL, petRow!.last_fed_at);
  const newHunger = Math.min(100, currentHunger + (item.hunger_restore ?? 30));

  await db
    .prepare(
      `UPDATE user_pets
       SET hunger = ?, coins = coins - ?, last_fed_at = datetime('now'), updated_at = datetime('now')
       WHERE uid = ?`
    )
    .bind(newHunger, item.price, uid)
    .run();

  return c.json<ApiResponse<{ hunger: number; coins_spent: number }>>({
    success: true,
    data: { hunger: newHunger, coins_spent: item.price }
  });
});

/**
 * POST /api/v1/home/pet/play
 * Play with the pet — costs coins, restores happiness  { item_id }
 */
homeRoutes.post('/pet/play', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ item_id: string }>();

  const item = SHOP_CATALOG.find((s) => s.id === body.item_id && s.category === 'pet_toy');
  if (!item) return c.json<ApiResponse>({ success: false, error: 'Đồ chơi không hợp lệ' }, 400);

  await ensurePet(db, uid);
  const petRow = await db.prepare('SELECT * FROM user_pets WHERE uid = ?').bind(uid).first<PetRow>();

  if (petRow!.coins < item.price) {
    return c.json<ApiResponse>({ success: false, error: `Không đủ coin (cần ${item.price}, có ${petRow!.coins})` }, 400);
  }

  const currentHappiness = calcDecayed(petRow!.happiness, HAPPINESS_DECAY_PER_INTERVAL, petRow!.last_played_at);
  const newHappiness = Math.min(100, currentHappiness + (item.happiness_restore ?? 25));

  await db
    .prepare(
      `UPDATE user_pets
       SET happiness = ?, coins = coins - ?, last_played_at = datetime('now'), updated_at = datetime('now')
       WHERE uid = ?`
    )
    .bind(newHappiness, item.price, uid)
    .run();

  return c.json<ApiResponse<{ happiness: number; xp_bonus_pct: number; coins_spent: number }>>({
    success: true,
    data: {
      happiness: newHappiness,
      xp_bonus_pct: petXpBonus(newHappiness),
      coins_spent: item.price,
    }
  });
});

/**
 * POST /api/v1/home/shop/buy
 * Buy a furniture item and place it in the room  { item_id, room_slot }
 */
homeRoutes.post('/shop/buy', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ item_id: string; room_slot: number }>();

  const item = SHOP_CATALOG.find((s) => s.id === body.item_id && s.category === 'furniture');
  if (!item) return c.json<ApiResponse>({ success: false, error: 'Đồ nội thất không tồn tại' }, 400);

  if (body.room_slot < 0 || body.room_slot > 15) {
    return c.json<ApiResponse>({ success: false, error: 'room_slot phải từ 0–15' }, 400);
  }

  await ensurePet(db, uid);
  const petRow = await db.prepare('SELECT coins FROM user_pets WHERE uid = ?').bind(uid).first<{ coins: number }>();

  if (petRow!.coins < item.price) {
    return c.json<ApiResponse>({ success: false, error: `Không đủ coin (cần ${item.price}, có ${petRow!.coins})` }, 400);
  }

  // Check slot not already occupied
  const slotOccupied = await db
    .prepare('SELECT id FROM home_furniture WHERE uid = ? AND room_slot = ?')
    .bind(uid, body.room_slot)
    .first();

  if (slotOccupied) {
    return c.json<ApiResponse>({ success: false, error: 'Vị trí phòng này đã có đồ. Chọn vị trí khác.' }, 400);
  }

  const furnitureId = `furn-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;

  await db.batch([
    db.prepare(
      `INSERT INTO home_furniture (id, uid, item_id, room_slot) VALUES (?, ?, ?, ?)`
    ).bind(furnitureId, uid, body.item_id, body.room_slot),
    db.prepare(
      `UPDATE user_pets SET coins = coins - ?, updated_at = datetime('now') WHERE uid = ?`
    ).bind(item.price, uid),
  ]);

  return c.json<ApiResponse<{ furniture_id: string; coins_spent: number }>>({
    success: true,
    data: { furniture_id: furnitureId, coins_spent: item.price }
  });
});

/**
 * DELETE /api/v1/home/furniture/:id
 * Remove a placed furniture item (no refund — intentional design)
 */
homeRoutes.delete('/furniture/:id', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const furnitureId = c.req.param('id');

  const result = await db
    .prepare('DELETE FROM home_furniture WHERE id = ? AND uid = ?')
    .bind(furnitureId, uid)
    .run();

  if (result.meta.changes === 0) {
    return c.json<ApiResponse>({ success: false, error: 'Đồ nội thất không tồn tại' }, 404);
  }

  return c.json<ApiResponse>({ success: true });
});

/**
 * PATCH /api/v1/home/pet/rename
 * Rename the pet  { name }
 */
homeRoutes.patch('/pet/rename', async (c) => {
  const { uid } = c.get('auth');
  const db = c.env.DB;
  const body = await c.req.json<{ name: string }>();

  const name = (body.name ?? '').trim().substring(0, 20);
  if (!name) return c.json<ApiResponse>({ success: false, error: 'Tên pet không được để trống' }, 400);

  await ensurePet(db, uid);
  await db
    .prepare(`UPDATE user_pets SET pet_name = ?, updated_at = datetime('now') WHERE uid = ?`)
    .bind(name, uid)
    .run();

  return c.json<ApiResponse>({ success: true });
});
