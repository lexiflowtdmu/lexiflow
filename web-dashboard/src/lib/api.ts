import { auth } from './firebase';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://lexiflow-api.quoctrunghrnk.workers.dev/api/v1';

async function getToken(): Promise<string | null> {
  const user = auth.currentUser;
  if (!user) return null;
  return user.getIdToken();
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = await getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }
  if (res.status === 204) return {} as T;
  return res.json();
}

// ── Helpers ──────────────────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function vocabToFlashcard(v: any): Flashcard {
  return {
    id: v.id,
    word: v.word,
    definition: v.meaning || v.definition || '',
    phonetic: v.phonetic || '',
    interval: v.interval ?? 0,
    easeFactor: v.ease_factor ?? v.easeFactor ?? 2.5,
    repetitions: v.repetitions ?? 0,
    nextReview: v.next_review || v.nextReview || '',
  };
}

// ── Streak ──────────────────────────────────────────────────────────────────
export const getStreak = async (): Promise<{ streakDays: number; lastActivity: string }> => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r: any = await request('/streak');
  return { streakDays: r.streak ?? r.streakDays ?? 0, lastActivity: r.lastActivity || '' };
};
export const updateStreak = () => request<{ streakDays: number }>('/streak', { method: 'POST' });

// ── Flashcards ───────────────────────────────────────────────────────────────
export const getFlashcards = async (): Promise<{ flashcards: Flashcard[] }> => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r: any = await request('/flashcards');
  const raw = Array.isArray(r.vocabs) ? r.vocabs : Array.isArray(r.flashcards) ? r.flashcards : [];
  return { flashcards: raw.map(vocabToFlashcard) };
};
export const getDueFlashcards = async (): Promise<{ flashcards: Flashcard[] }> => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r: any = await request('/flashcards/due');
  const raw = Array.isArray(r.vocabs) ? r.vocabs : Array.isArray(r.flashcards) ? r.flashcards : [];
  return { flashcards: raw.map(vocabToFlashcard) };
};
export const saveFlashcard = (word: string, definition: string) =>
  request('/flashcards', { method: 'POST', body: JSON.stringify({ word, definition }) });
export const deleteFlashcard = (id: string) =>
  request(`/flashcards/${id}`, { method: 'DELETE' });
export const reviewFlashcard = (data: ReviewEventPayload) =>
  request('/flashcards/review-events', { method: 'POST', body: JSON.stringify(data) });

// ── History ───────────────────────────────────────────────────────────────────
export const getHistory = async (): Promise<{ history: HistoryItem[] }> => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r: any = await request('/history');
  const raw = Array.isArray(r.history) ? r.history : [];
  return {
    history: raw.map((h: any) => ({ // eslint-disable-line @typescript-eslint/no-explicit-any
      word: h.word,
      searchedAt: h.timestamp || h.searchedAt || h.created_at || new Date().toISOString(),
    })),
  };
};
export const addHistory = (word: string) =>
  request('/history', { method: 'POST', body: JSON.stringify({ word }) });
export const deleteHistory = (word: string) =>
  request(`/history/${encodeURIComponent(word)}`, { method: 'DELETE' });

// ── Bookmarks ─────────────────────────────────────────────────────────────────
export const getBookmarks = () => request<{ bookmarks: BookmarkItem[] }>('/bookmarks/list');
export const toggleBookmark = (word: string, definition?: string, phonetic?: string) =>
  request('/bookmarks', { method: 'POST', body: JSON.stringify({ word, definition, phonetic }) });

// ── Decks ─────────────────────────────────────────────────────────────────────
export const getDecksSummary = () => request<{ decks: DeckSummary[] }>('/decks/summary');

// ── Farm ──────────────────────────────────────────────────────────────────────
const STAGE_MAP: Record<number, FarmPlot['stage']> = { 0: 'empty', 1: 'growing', 2: 'ready' };

export const getFarmState = async (): Promise<FarmState> => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r: any = await request('/farm/state');
  const d = r.data ?? r;
  return {
    coins: d.coins ?? 0,
    plots: (Array.isArray(d.plots) ? d.plots : []).map((p: any) => ({ // eslint-disable-line
      id: p.slot_index ?? 0,
      dbId: String(p.id ?? p.slot_index ?? 0),
      crop: p.crop_type || undefined,
      stage: STAGE_MAP[p.stage as number] ?? 'empty',
      waterCount: p.words_progress ?? 0,
      requiredWater: p.words_needed ?? 5,
    })),
    pendingOrders: (Array.isArray(d.orders) ? d.orders : []).map((o: any) => ({ // eslint-disable-line
      id: o.id,
      crop: (Array.isArray(o.items) && o.items[0]?.type) ? o.items[0].type : 'corn',
      reward: o.reward_coins ?? o.reward ?? 0,
      deadline: o.expires_at || new Date().toISOString(),
      items: Array.isArray(o.items) ? o.items : [],
      rewardXp: o.reward_xp ?? 0,
    })),
    inventory: d.inventory ?? {},
    cropCatalog: d.crop_catalog ?? {},
  };
};
export const plantCrop = (slotIndex: number, cropType: string) =>
  request('/farm/plant', { method: 'POST', body: JSON.stringify({ slot_index: slotIndex, crop_type: cropType }) });
export const waterPlant = (drops = 1) =>
  request('/farm/water', { method: 'POST', body: JSON.stringify({ drops }) });
export const harvestCrop = async (dbId: string): Promise<{ crop_type: string; amount: number }> => {
  const r = await request<{ data: { crop_type: string; amount: number } }>('/farm/harvest', {
    method: 'POST',
    body: JSON.stringify({ plot_id: dbId }),
  });
  return r.data;
};
export const fulfillFarmOrder = async (orderId: string): Promise<{ coins_earned: number; xp_earned: number }> => {
  const r = await request<{ data: { coins_earned: number; xp_earned: number } }>(
    `/farm/orders/${encodeURIComponent(orderId)}/fulfill`,
    { method: 'POST', body: '{}' },
  );
  return r.data;
};

// ── Admin ─────────────────────────────────────────────────────────────────────
export const getAdminStats = () => request<AdminStats>('/admin/stats');
export const getAdminUsers = (page = 1, limit = 20) =>
  request<{ users: AdminUser[]; total: number }>(`/admin/users?page=${page}&limit=${limit}`);
export const banUser = (uid: string, reason: string) =>
  request(`/admin/users/${uid}/ban`, { method: 'POST', body: JSON.stringify({ reason }) });
export const unbanUser = (uid: string) =>
  request(`/admin/users/${uid}/unban`, { method: 'POST' });
export const getAdminLeaderboard = () =>
  request<{ leaderboard: LeaderboardEntry[] }>('/admin/leaderboard');

// ── Types ────────────────────────────────────────────────────────────────────
export interface Flashcard {
  id: string;
  word: string;
  definition: string;
  phonetic?: string;
  interval: number;
  easeFactor: number;
  repetitions: number;
  nextReview: string;
}

export interface ReviewEventPayload {
  flashcardId: string;
  quality: number; // 0-5
}

export interface HistoryItem {
  word: string;
  searchedAt: string;
}

export interface BookmarkItem {
  word: string;
  definition?: string;
  phonetic?: string;
  savedAt: string;
}

export interface DeckSummary {
  name: string;
  total: number;
  due: number;
  mastered: number;
}

export interface FarmState {
  coins: number;
  plots: FarmPlot[];
  pendingOrders: FarmOrder[];
  inventory: Record<string, number>;
  cropCatalog: Record<string, { name: string; emoji: string; words_needed: number; base_price: number }>;
}

export interface FarmPlot {
  id: number;     // slot_index (0–7) for display
  dbId: string;   // actual DB id for harvest API
  crop?: string;
  stage: 'empty' | 'seeded' | 'growing' | 'ready';
  waterCount: number;
  requiredWater: number;
}

export interface FarmOrder {
  id: string;
  crop: string;
  reward: number;
  deadline: string;
  items: { type: string; qty: number }[];
  rewardXp: number;
}

export interface AdminStats {
  totalUsers: number;
  activeToday: number;
  totalWords: number;
  totalFlashcards: number;
  avgStreak: number;
}

export interface AdminUser {
  uid: string;
  email: string;
  displayName: string;
  streak: number;
  totalWords: number;
  banned: boolean;
  createdAt: string;
}

export interface LeaderboardEntry {
  uid: string;
  displayName: string;
  xp: number;
  streak: number;
  rank: number;
}
