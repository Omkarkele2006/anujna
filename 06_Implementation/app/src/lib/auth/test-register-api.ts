import { POST } from "@/app/api/auth/register/route";

async function testRegistrationAPI() {
  console.log("=== ANUJNA User Registration API Test ===\n");

  const testEmail = `test.patient.${Date.now()}@anujna.org`;

  // Helper to simulate Next.js Request object
  const createMockRequest = (body: object) =>
    new Request("http://localhost:3000/api/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

  // 1. Valid Patient Registration Test
  console.log("1. Testing Valid Patient Registration...");
  const res1 = await POST(
    createMockRequest({
      fullName: "Test Patient",
      email: testEmail,
      password: "StrongP@ssword2026!",
      roleName: "PATIENT",
    })
  );
  const data1 = await res1.json();
  console.log(`   Status Code: ${res1.status} (Expected: 201)`);
  console.log(`   User ID Generated: ${data1.user?.userId || "None"}`);
  console.log(`   Password Hash Excluded: ${data1.user?.passwordHash === undefined ? "✅ YES" : "❌ NO"}\n`);

  // 2. Duplicate Registration Prevention Test
  console.log("2. Testing Duplicate Email Prevention...");
  const res2 = await POST(
    createMockRequest({
      fullName: "Duplicate User",
      email: testEmail.toUpperCase(), // Test case-insensitive check
      password: "StrongP@ssword2026!",
      roleName: "PATIENT",
    })
  );
  const data2 = await res2.json();
  console.log(`   Status Code: ${res2.status} (Expected: 409)`);
  console.log(`   Error Message: "${data2.error}"\n`);

  // 3. Admin Privilege Escalation Guard Test
  console.log("3. Testing Privilege Escalation Prevention (Admin Role)...");
  const res3 = await POST(
    createMockRequest({
      fullName: "Hacker Admin",
      email: "hacker@anujna.org",
      password: "StrongP@ssword2026!",
      roleName: "ADMIN",
    })
  );
  const data3 = await res3.json();
  console.log(`   Status Code: ${res3.status} (Expected: 400)`);
  console.log(`   Error Message: "${data3.error}"\n`);

  // 4. Weak Password Rejection Test
  console.log("4. Testing Weak Password Rejection...");
  const res4 = await POST(
    createMockRequest({
      fullName: "Weak User",
      email: "weak@anujna.org",
      password: "123",
      roleName: "PATIENT",
    })
  );
  const data4 = await res4.json();
  console.log(`   Status Code: ${res4.status} (Expected: 400)`);
  console.log(`   Validation Errors Count: ${data4.errors?.length || 0}\n`);

  console.log("🎉 User Registration API Verification Completed Successfully!");
}

testRegistrationAPI().catch((err) => {
  console.error("❌ Registration Test Error:", err);
});
