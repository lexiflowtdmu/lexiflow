// ============================================================
// Input Sanitization Utilities
// ============================================================

/**
 * Sanitize string input to prevent XSS and other injection attacks
 * Removes dangerous characters and limits length
 */
export function sanitizeString(input: string, maxLength: number = 1000): string {
  if (typeof input !== 'string') {
    return '';
  }
  
  // Trim and limit length
  let sanitized = input.trim().substring(0, maxLength);
  
  // Remove null bytes
  sanitized = sanitized.replace(/\0/g, '');
  
  // Remove control characters (except newline, tab, carriage return)
  sanitized = sanitized.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  
  return sanitized;
}

/**
 * Validate and sanitize word input (stricter rules)
 */
export function sanitizeWord(input: string): string {
  const sanitized = sanitizeString(input, 200);
  
  // Words should only contain letters, numbers, spaces, hyphens, apostrophes
  // Allow Vietnamese characters
  return sanitized.replace(/[^\p{L}\p{N}\s\-'']/gu, '').trim();
}

import type { Context } from 'hono';

/**
 * Extracts and decodes a word parameter from the request URL, ensuring it is valid.
 * Returns null if the word is missing or empty.
 */
export function getValidWordParam(c: Context, paramName: string = 'word'): string | null {
  const param = c.req.param(paramName);
  if (!param) return null;
  const word = decodeURIComponent(param).trim().toLowerCase();
  return word.length > 0 ? word : null;
}
