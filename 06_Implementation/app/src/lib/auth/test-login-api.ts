import { POST as registerHandler } from "@/app/api/auth/register/route";
import { POST as loginHandler } from "@/app/api/auth/login/route";

async function testLoginAPI() {
  console.log("=== ANUJNA User Login API Test ===\n");

  const testEmail = `login.test.${Date.now()}@anujna.org`;
  const testPassword = "StrongP@ssword2026!";

  // 0. Seed a test patient account
  await registerHandler(
    new Request("http://localhost:3000/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "Login Test Patient",
        email: testEmail,
        password: testPassword,
        roleName: "PATIENT",
      }),
    })
  );

  const createMockLoginRequest = (body: object) =>
    new Request("http://localhost:3000/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

  // 1. Valid Login Test
  console.log("1. Testing Valid Credential Login...");
  const res1 = await loginHandler(
    createMockLoginRequest({ email: testEmail, password: testPassword })
  );
  const data1 = await res1.json();
  const setCookieHeader = res1.headers.get("set-cookie") || "";

  console.log(`   Status Code: ${res1.status} (Expected: 200)`);
  console.log(`   User Returned: ${data1.user?.email}`);
  console.log(`   Roles: ${data1.user?.roles.join(", ")}`);
  console.log(`   HTTP-Only Cookie Attached: ${setCookieHeader.includes("anujna_token") ? "✅ YES" : "❌ NO"}\n`);

  // 2. Wrong Password Test (Account Enumeration Check)
  console.log("2. Testing Wrong Password Mismatch...");
  const res2 = await loginHandler(
    createMockLoginRequest({ email: testEmail, password: "WrongPassword123!" })
  );
  const data2 = await res2.json();
  console.log(`   Status Code: ${res2.status} (Expected: 401)`);
  console.log(`   Error Message: "${data2.error}"\n`);

  // 3. Non-Existent Account Test (Account Enumeration Check)
  console.log("3. Testing Non-Existent Account Email...");
  const res3 = await loginHandler(
    createMockLoginRequest({ email: "doesnotexist@anujna.org", password: testPassword })
  );
  const data3 = await res3.json();
  console.log(`   Status Code: ${res3.status} (Expected: 401)`);
  console.log(`   Error Message Mismatch Guard: ${data2.error === data3.error ? "✅ PASSED (Identical Error)" : "❌ FAILED"}\n`);

  console.log("🎉 User Login API Verification Completed Successfully!");
}

testLoginAPI().catch((err) => {
  console.error("❌ Login Test Error:", err);
});
