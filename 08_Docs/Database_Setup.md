# ANUJNA – Database Setup & Administration Guide

**Document Version:** 1.0  
**Target Engine:** PostgreSQL 14+  
**ORM Framework:** Prisma ORM v7  

---

## 1. Overview

This document details the environment configuration, schema deployment, migration execution, and database seeding procedures for the **ANUJNA** Consent-Driven Unified Health Identity Platform.

---

## 2. PostgreSQL Setup

### Prerequisites
* **PostgreSQL Engine:** PostgreSQL v14.0 or higher running locally or hosted (e.g., AWS RDS, Supabase, Neon).
* **Extension Requirement:** The database requires the `pgcrypto` or `uuid-ossp` extension enabled for standard `gen_random_uuid()` generation.
* **Timezone:** Ensure database engine default timezone is set to `UTC` to align with `@db.Timestamptz(6)` field timestamps across all audit and consent records.

### Database Creation SQL
```sql
-- Connect as superuser (postgres)
CREATE DATABASE anujna;

-- Connect to anujna database
\c anujna;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

---

## 3. `.env` Environment Configuration

The application reads database credentials from `06_Implementation/app/.env`.

Create or edit `06_Implementation/app/.env` with your PostgreSQL connection URL:

```env
DATABASE_URL="postgresql://<USERNAME>:<PASSWORD>@<HOST>:<PORT>/<DATABASE_NAME>?schema=public"
```

### Example (Local Development):
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/anujna?schema=public"
```

---

## 4. Prisma Database Workflows & Scripts

All database scripts are configured in `06_Implementation/app/package.json` and `prisma.config.ts`. Run commands from within the `06_Implementation/app` directory.

### 4.1 Prisma Client Generation (`db:generate`)
Generates the type-safe Prisma Client TypeScript definitions based on `prisma/schema.prisma`.

```bash
npm run db:generate
# Alternative CLI command:
npx prisma generate
```

### 4.2 Database Migration (`db:migrate`)
Applies pending schema changes to the target database and maintains migration tracking in the `_prisma_migrations` table.

```bash
npm run db:migrate
# Alternative CLI command:
npx prisma migrate dev --name <migration_name>
```

### 4.3 Database Seeding (`db:seed`)
Executes `prisma/seed.ts` using `tsx` to insert default system roles (`ADMIN`, `DOCTOR`, `PATIENT`) into the database. Seeding is **idempotent** (using `upsert` on `roleName` to prevent duplicates).

```bash
npm run db:seed
# Alternative CLI command:
npx prisma db seed
```

### 4.4 Prisma Studio Visualizer (`db:studio`)
Launches the interactive visual web client to inspect and manage tables, records, and relationships.

```bash
npm run db:studio
# Alternative CLI command:
npx prisma studio
```

---

## 5. Verification Check

To quickly verify database connectivity and baseline role insertion, run:

```bash
npx tsx src/lib/test-db.ts
npm run db:seed
```
