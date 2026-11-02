// ============================================================
// Rate Limiting Middleware
// ============================================================

import type { Context, Next } from 'hono';
import type { Bindings } from '../types';

interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}

// Simple in-memory rate limiter (for production, use KV or Durable Objects)
const requestCounts = new Map<string, { count: number; resetTime: number }>();
const CLEANUP_INTERVAL_MS = 5 * 60 * 1000;
let nextCleanupAt = 0;

/**
 * Rate limiting middleware
 * @param config - maxRequests: số request tối đa, windowMs: cửa sổ thời gian (ms)
 */
export function rateLimitMiddleware(config: RateLimitConfig) {
  return async (c: Context<{ Bindings: Bindings }>, next: Next) => {
    const clientIP = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || 'unknown';
    const now = Date.now();

    // Workers forbid timers at global scope, so stale entries are cleared during requests.
    if (now >= nextCleanupAt) {
      nextCleanupAt = now + CLEANUP_INTERVAL_MS;
      for (const [key, data] of requestCounts.entries()) {
        if (now > data.resetTime) requestCounts.delete(key);
      }
    }

    const clientData = requestCounts.get(clientIP);
    
    if (!clientData || now > clientData.resetTime) {
      // New window
      requestCounts.set(clientIP, {
        count: 1,
        resetTime: now + config.windowMs,
      });
      await next();
      return;
    }
    
    if (clientData.count >= config.maxRequests) {
      // Rate limit exceeded
      return c.json(
        {
          success: false,
          error: 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
        },
        429
      );
    }
    
    // Increment count
    clientData.count++;
    await next();
  };
}

