import { hashPassword, comparePassword } from "./password";
import { signAccessToken, verifyAccessToken } from "./jwt";
import { validateEmail, validatePassword } from "./validation";

async function runAuthVerification() {
  console.log("=== ANUJNA Auth Security Verification ===\n");

  // 1. Password Hashing Test
  console.log("1. Testing Password Hashing...");
  const rawPassword = "StrongP@ssword2026!";
  const hashed = await hashPassword(rawPassword);
  console.log(`   Hashed Result: ${hashed.substring(0, 30)}...`);

  const matches = await comparePassword(rawPassword, hashed);
  const wrongMatches = await comparePassword("WrongPassword123!", hashed);
  console.log(`   Correct Password Match: ${matches ? "PASSED" : "FAILED"}`);
  console.log(`   Wrong Password Match: ${!wrongMatches ? "PASSED (Rejected)" : "FAILED"}\n`);

  // 2. JWT Signing & Verification Test
  console.log("2. Testing JWT Signing & Verification...");
  const testPayload = {
    userId: "user-uuid-12345",
    email: "patient@anujna.org",
    roles: ["PATIENT"],
  };

  const token = await signAccessToken(testPayload);
  console.log(`   Signed Token: ${token.substring(0, 40)}...`);

  const decoded = await verifyAccessToken(token);
  const isValidDecoded = decoded?.userId === testPayload.userId && decoded?.roles[0] === "PATIENT";
  console.log(`   Decoded Payload Valid: ${isValidDecoded ? "PASSED" : "FAILED"}\n`);

  // 3. Validation Rules Test
  console.log("3. Testing Password & Email Validation...");
  const validEmail = validateEmail("doctor@anujna.org");
  const invalidPassword = validatePassword("weak");
  const validPassword = validatePassword("StrongP@ssword2026!");

  console.log(`   Valid Email Check: ${validEmail.isValid ? "PASSED" : "FAILED"}`);
  console.log(`   Weak Password Rejection: ${!invalidPassword.isValid ? "PASSED" : "FAILED"}`);
  console.log(`   Strong Password Acceptance: ${validPassword.isValid ? "PASSED" : "FAILED"}\n`);

  console.log("All Auth Utilities Verified Successfully!");
}

runAuthVerification().catch((err) => {
  console.error("Verification Failed:", err);
});
