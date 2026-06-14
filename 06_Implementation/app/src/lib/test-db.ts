import { prisma } from "./prisma";

async function main() {
  console.log("Testing ANUJNA database connectivity...");
  try {
    // Queries the users table count to verify access and authentication
    const count = await prisma.user.count();
    console.log(`\n🎉 Connection Successful!`);
    console.log(`Total users in database: ${count}\n`);
  } catch (error) {
    console.error("\n❌ Database connection failed!");
    console.error("Error details:", error);
    console.log("\nPlease check your DATABASE_URL in .env and verify network access.\n");
  } finally {
    await prisma.$disconnect();
  }
}

main();
