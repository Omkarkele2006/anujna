# ANUJNA – Migration-Readiness Review (v1.0)

**Document ID:** ANJ-MRR-v1.0  
**Project:** ANUJNA – Consent-Driven Unified Health Identity Platform  
**Database Target:** PostgreSQL 14+  
**Schema Version:** Prisma Schema v1.0 (Frozen)  

---

## 1. Introduction

This review evaluates the **ANUJNA schema.prisma v1.0** for physical migration readiness on a target PostgreSQL instance. It checks schema integrity, PostgreSQL-specific extensions, indexing coverage, soft-delete constraints, cascade delete strategies, and identifies steps required to run the initial migration safely in a production environment.

---

## 2. PostgreSQL Configuration Requirements

### 2.1 Extension Dependency: `pgcrypto` or `uuid-ossp`
* **Requirement:** The schema uses `gen_random_uuid()` for generating primary keys on PostgreSQL.
* **Risk:** If the database does not have the extension enabled, the migration will fail on table creation.
* **Action:** The migration SQL must explicitly create the extension prior to creating any tables.
```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

### 2.2 Timezone Mapping
* **Requirement:** All transaction, log, and consent timestamps use `@db.Timestamptz(6)`.
* **Impact:** This ensures database-level timezone offset storage, avoiding errors from server-client offset mismatch (standard health platform requirement).
* **Action:** The database engine's timezone should default to `UTC` to maintain standard tracking.

---

## 3. SQL DDL Generation Summary

Prisma Migrate will compile `schema.prisma` into a SQL file. The generated DDL will execute the following operations in order:

1. **Enum Initialization:** Creation of custom enum types (`AccountStatus`, `VerificationStatus`, `NotificationStatus`, `RecordType`, `RequestStatus`, `ConsentScope`, `ConsentStatus`, `NotificationType`, `AuditActionType`).
2. **Table Creation:**
   * Creates the 15 base tables using double quotes mapping to `@map`/`@@map`.
   * Columns are mapped with appropriate constraints (e.g., `VARCHAR(255)`, `UUID`, `TIMESTAMPTZ(6)`, `DATE`).
3. **Foreign Keys Setup:** Defines standard FK references.
4. **Index Setup:** Establishes unique indices (e.g., email, registration number) and search indices.

---

## 4. Referential Action & Cascade Review

To prevent orphan records, referential actions are specified:
* **Cascade Deletes (`onDelete: Cascade`):**
   * Removing a `User` cascades to `UserRole`, `PatientProfile`, `DoctorProfile`, `DoctorVerificationRequest`, `Notification`, and `AuditLog` references.
   * Removing a `PatientProfile` cascades to `HealthIdentity`, `HealthRecord`, `AccessRequest`, and `EmergencyAccessEvent`.
   * Removing a `Consent` cascades to `ConsentHealthRecord`.
   * Removing an `EmergencyAccessEvent` cascades to `EmergencyAccessRecord`.
* **Restrict Deletes (`onDelete: Restrict`):**
   * `HealthRecord.uploadedByUserId` uses `onDelete: Restrict`. This prevents deleting laboratory staff or doctor accounts if they have uploaded historical records for patients, preventing data integrity loss.
* **Set Null Deletes (`onDelete: SetNull`):**
   * `AuditLog.userId` and `DoctorVerificationRequest.reviewedByUserId` use `onDelete: SetNull`. This ensures that even if an Admin or Auditor account is removed, the historical audit log and review trails remain intact.

---

## 5. Lifecycle & Soft-Delete Enforcement

For the entities tracking healthcare data or critical access privileges (`HealthRecord`, `Consent`, `Notification`), soft deletion is mapped using a nullable `deleted_at` timestamp.
* **Database Level:** The columns allow `NULL` values.
* **Application Level (Prisma Client Middleware):**
  * Developers **must** configure a Prisma middleware or extension to automatically intercept `findMany`, `findFirst`, `findUnique`, and `update` queries to filter out rows where `deleted_at` is not null.
  * **Sample Prisma Client Extension:**
    ```typescript
    prisma.$extends({
      query: {
        healthRecord: {
          async findMany({ args, query }) {
            args.where = { ...args.where, deletedAt: null };
            return query(args);
          },
        },
      },
    });
    ```

---

## 6. Migration Operational Checklist

Before executing `npx prisma migrate dev` or `npx prisma db push`, verify:

- [ ] **Database Connection:** `DATABASE_URL` is set in `.env` pointing to a PostgreSQL database with root-level privileges (needed to enable the `pgcrypto` extension).
- [ ] **Extension Permission:** The user credential has `SUPERUSER` or `CREATE` privileges on the schema to load `pgcrypto`.
- [ ] **Nullable/Defaults Checks:** All nullable fields (`metadata`, `ip_address`, `record_type`, `requested_category`) do not have default constraints that could cause schema conflicts.
- [ ] **Database Baseline:** The target database is empty, or the migration history is baselined if migrating an existing schema.

---

## 7. Conclusion

The **ANUJNA schema.prisma v1.0** is **migration-ready**. It satisfies all logical rules defined in LDD v1.1, matches PostgreSQL standards, enforces indexes for target performance constraints, and safely isolates demographic records.
