import { defineConfig, env } from "prisma/config";

// Load environment variables from .env file using Node 22's native support
process.loadEnvFile();

export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: {
    url: env("DATABASE_URL"),
  },
});

