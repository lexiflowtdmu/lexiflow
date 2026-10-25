// ============================================================
// Shared TypeScript types for LexiFlow Worker API
// ============================================================

/** JWT payload extracted after Firebase token verification */
export interface AuthContext {
  uid: string;
  email?: string;
}

/** Variables injected into Hono context via middleware */
export interface Bindings {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
  ADMIN_UIDS?: string; // Comma-separated list of admin UIDs for privileged endpoints
}

/** Variables attached to Hono context by auth middleware */
export interface Variables {
  auth: AuthContext;
}

/** Flashcard / Spaced Repetition record */
export interface Flashcard {
  id: string;
  uid: string;
  word: string;
  meaning: string;
  example: string;
  interval: number;
  ease_factor: number;
  repetitions: number;
  next_review: string;
  created_at: string;
  updated_at: string;
}

/** Request body for creating/updating a flashcard */
export interface FlashcardInput {
  id?: string;
  word: string;
  meaning: string;
  example?: string;
  interval?: number;
  easeFactor?: number;
  ease_factor?: number;
  repetitions?: number;
  nextReview?: string;
  next_review?: string;
}


/** Search history record */
export interface HistoryItem {
  id: string;
  uid: string;
  word: string;
  translation: string;
  timestamp: string;
}

/** Bookmark record */
export interface BookmarkItem {
  uid: string;
  word: string;
  translation: string;
  created_at: string;
}

/** Study streak record */
export interface StudyStreak {
  uid: string;
  current_streak: number;
  longest_streak: number;
  last_study_date: string;
}

/** User Profile record */
export interface UserProfile {
  uid: string;
  email: string;
  display_name: string;
  avatar_url: string;
  user_code: string; // e.g. '#LEXI-8921'
  is_public_profile: number; // 0: friends only, 1: public to all
  level: number;
  xp: number;
  created_at: string;
  updated_at: string;
}

/** Friendship record */
export interface Friendship {
  id: string;
  requester_uid: string;
  receiver_uid: string;
  status: 'pending' | 'accepted' | 'rejected' | 'blocked';
  created_at: string;
  updated_at: string;
}

/** Friend User Record with Profile & Relationship Status */
export interface FriendUser {
  uid: string;
  email: string;
  display_name: string;
  avatar_url: string;
  user_code: string;
  is_public_profile: number;
  level: number;
  xp: number;
  current_streak?: number;
  relationshipStatus?: 'none' | 'pending_sent' | 'pending_received' | 'accepted' | 'blocked';
}

/** Standard JSON API response */
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}
