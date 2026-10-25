// ============================================================
// Auth Middleware — Firebase JWT Verification
// ============================================================

import { jwtVerify, createRemoteJWKSet } from 'jose';
import type { Context, Next } from 'hono';
import type { AuthContext, Bindings } from '../types';

// Firebase Auth public keys URL
const JWKS_URL = 'https://www.googleapis.com/robot/v1/metadata/jwk/securetoken@system.gserviceaccount.com';
const JWKS = createRemoteJWKSet(new URL(JWKS_URL));


/**
 * Hono middleware that verifies Firebase JWT from Authorization header.
 * On success, sets `c.var.auth` with uid and email.
 * On failure, returns 401 JSON response.
 */
export async function authMiddleware(c: Context<{ Bindings: Bindings; Variables: { auth: AuthContext } }>, next: Next) {
  const authHeader = c.req.header('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json(
      { success: false, error: 'Thiếu token xác thực. Vui lòng đăng nhập lại.' },
      401
    );
  }

  const token = authHeader.substring(7);

  try {
    const projectId = c.env.FIREBASE_PROJECT_ID || 'vocabofinalapp';

    const { payload } = await jwtVerify(token, JWKS, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
    });

    // Validate required fields
    if (!payload.sub || typeof payload.sub !== 'string') {
      console.error('JWT missing or invalid sub claim');
      return c.json(
        { success: false, error: 'Token không hợp lệ. Vui lòng đăng nhập lại.' },
        401
      );
    }

    const auth: AuthContext = {
      uid: payload.sub as string,
      email: (payload.email as string | undefined) || undefined,
    };

    c.set('auth', auth);

    // Check if user is banned (skip for admin UIDs so they can still manage accounts)
    const adminUids = (c.env.ADMIN_UIDS || '').split(',').map((s: string) => s.trim()).filter(Boolean);
    if (!adminUids.includes(auth.uid)) {
      const userRow = await c.env.DB
        .prepare('SELECT is_banned FROM users WHERE uid = ?')
        .bind(auth.uid)
        .first<{ is_banned: number }>();
      if (userRow?.is_banned === 1) {
        return c.json(
          { success: false, error: 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.' },
          403
        );
      }
    }

    await next();
  } catch (error) {
    console.error('JWT verification failed:', error);
    return c.json(
      { success: false, error: 'Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.' },
      401
    );
  }
}
