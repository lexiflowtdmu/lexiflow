-- ============================================================
-- Migration 0004: Admin — Ban/Unban + Curated Base Content
-- ============================================================

-- Add ban fields to users table
ALTER TABLE users ADD COLUMN is_banned INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN banned_reason TEXT;
ALTER TABLE users ADD COLUMN banned_at TEXT;

-- Curated / Base-Data Content
-- Admin-selected flashcards promoted to become official base vocabulary
CREATE TABLE IF NOT EXISTS curated_content (
    id              TEXT NOT NULL PRIMARY KEY,
    word            TEXT NOT NULL UNIQUE,
    meaning         TEXT NOT NULL,
    example         TEXT NOT NULL DEFAULT '',
    source_uid      TEXT,           -- original owner's uid
    source_card_id  TEXT UNIQUE,    -- original flashcard id
    category        TEXT NOT NULL DEFAULT 'general',
    promoted_by     TEXT NOT NULL,  -- admin uid who promoted it
    promoted_at     TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_curated_word ON curated_content(word);
CREATE INDEX IF NOT EXISTS idx_curated_promoted_at ON curated_content(promoted_at DESC);
