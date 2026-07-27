import bcrypt from "bcryptjs";

// OWASP recommended salt rounds for bcrypt
const SALT_ROUNDS = 12;

/**
 * Hashes a plain text password using bcrypt with 12 salt rounds.
 */
export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Compares a plain text password against a stored bcrypt hash.
 * This operation is timing-safe to prevent side-channel timing attacks.
 */
export async function comparePassword(
  plainText: string,
  hashedPassword: string
): Promise<boolean> {
  return await bcrypt.compare(plainText, hashedPassword);
}
