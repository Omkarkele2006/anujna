export default {
  schema: "05_Database/Prisma/schema.prisma",
  datasource: {
    url: process.env.DATABASE_URL || "postgresql://postgres:postgres@localhost:5432/anujna?schema=public",
  },
};
