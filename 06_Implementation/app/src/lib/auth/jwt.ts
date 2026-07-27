import { SignJWT, jwtVerify, JWTPayload } from "jose";

// Ensure process environment variables are loaded
if (typeof process.loadEnvFile === "function") {
  try {
    process.loadEnvFile();
  } catch {
    // Environment already loaded or in production
  }
}

const JWT_SECRET = process.env.JWT_SECRET || "fallback_default_secret_key_32bytes_min";
const secretKey = new TextEncoder().encode(JWT_SECRET);

export interface AuthTokenPayload extends JWTPayload {
  userId: string;
  email: string;
  roles: string[];
}

/**
 * Signs a secure access token for an authenticated user.
 * Expires in 15 minutes.
 */
export async function signAccessToken(payload: Omit<AuthTokenPayload, keyof JWTPayload>): Promise<string> {
  return await new SignJWT({ ...payload })
    .setProtectedHeader({ alg: "HS256" })
    .setIssuedAt()
    .setIssuer("anujna-auth")
    .setExpirationTime("15m")
    .sign(secretKey);
}

/**
 * Verifies a JWT token signature and checks expiration.
 * Returns decoded payload if valid, or null if invalid/expired.
 */
export async function verifyAccessToken(token: string): Promise<AuthTokenPayload | null> {
  try {
    const { payload } = await jwtVerify(token, secretKey, {
      issuer: "anujna-auth",
      algorithms: ["HS256"],
    });
    return payload as AuthTokenPayload;
  } catch {
    // Returns null on signature mismatch, expiration, or malformed token
    return null;
  }
}
