-- ============================================================
-- Migration 0003: Mini-Game — Farm × Home System
-- Farm plots, inventory, orders (Hay Day style) + Pet & Home
-- ============================================================

-- Farm Plots (8 slots per user)
CREATE TABLE IF NOT EXISTS farm_plots (
    id            TEXT    NOT NULL PRIMARY KEY,
    uid           TEXT    NOT NULL,
    slot_index    INTEGER NOT NULL,
    crop_type     TEXT,                                    -- NULL = empty slot
    planted_at    TEXT,
    words_needed  INTEGER NOT NULL DEFAULT 5,
    words_progress INTEGER NOT NULL DEFAULT 0,
    stage         INTEGER NOT NULL DEFAULT 0,             -- 0=empty 1=growing 2=ready
    UNIQUE(uid, slot_index)
);

CREATE INDEX IF NOT EXISTS idx_farm_plots_uid ON farm_plots(uid);

-- Farm Inventory (harvested goods stored per user)
CREATE TABLE IF NOT EXISTS farm_inventory (
    uid       TEXT NOT NULL,
    item_type TEXT NOT NULL,
    quantity  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (uid, item_type)
);

-- Farm Orders (Hay Day style, max 3 active per user)
CREATE TABLE IF NOT EXISTS farm_orders (
    id           TEXT NOT NULL PRIMARY KEY,
    uid          TEXT NOT NULL,
    items_json   TEXT NOT NULL,          -- JSON: [{"type":"corn","qty":3}, ...]
    reward_coins INTEGER NOT NULL DEFAULT 50,
    reward_xp    INTEGER NOT NULL DEFAULT 20,
    expires_at   TEXT NOT NULL,
    status       TEXT NOT NULL DEFAULT 'active',  -- active | fulfilled | expired
    created_at   TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_farm_orders_uid       ON farm_orders(uid);
CREATE INDEX IF NOT EXISTS idx_farm_orders_uid_status ON farm_orders(uid, status);

-- User Pets (1 per user, auto-created on first farm access)
-- Also stores the mini-game coin wallet
CREATE TABLE IF NOT EXISTS user_pets (
    uid            TEXT NOT NULL PRIMARY KEY,
    pet_type       TEXT NOT NULL DEFAULT 'cat',    -- cat | dog | bunny
    pet_name       TEXT NOT NULL DEFAULT 'Mochi',
    hunger         INTEGER NOT NULL DEFAULT 100,   -- 0–100, decays over time
    happiness      INTEGER NOT NULL DEFAULT 100,   -- 0–100, decays over time
    coins          INTEGER NOT NULL DEFAULT 50,    -- mini-game currency
    last_fed_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    last_played_at TEXT    NOT NULL DEFAULT (datetime('now')),
    created_at     TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at     TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- Home Furniture (items placed in user's home room)
CREATE TABLE IF NOT EXISTS home_furniture (
    id           TEXT NOT NULL PRIMARY KEY,
    uid          TEXT NOT NULL,
    item_id      TEXT NOT NULL,       -- catalog key e.g. 'sofa_basic'
    room_slot    INTEGER NOT NULL,    -- 0–15 grid position
    purchased_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_home_furniture_uid ON home_furniture(uid);
