-- CreateEnum
CREATE TYPE "AccountStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'INACTIVE');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('UNREAD', 'READ');

-- CreateEnum
CREATE TYPE "RecordType" AS ENUM ('LAB_REPORT', 'PRESCRIPTION', 'DIAGNOSTIC_REPORT', 'DISCHARGE_SUMMARY', 'VACCINATION_RECORD');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "ConsentScope" AS ENUM ('ALL', 'CATEGORY', 'INDIVIDUAL');

-- CreateEnum
CREATE TYPE "ConsentStatus" AS ENUM ('ACTIVE', 'REVOKED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('ACCESS_REQUEST', 'CONSENT_GRANTED', 'CONSENT_REVOKED', 'EMERGENCY_ACCESS', 'VERIFICATION_STATUS');

-- CreateEnum
CREATE TYPE "AuditActionType" AS ENUM ('LOGIN', 'LOGOUT', 'RECORD_VIEW', 'CONSENT_GRANTED', 'CONSENT_REVOKED', 'EMERGENCY_ACCESS', 'VERIFICATION_APPROVED', 'VERIFICATION_REJECTED');

-- CreateTable
CREATE TABLE "users" (
    "user_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "full_name" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "account_status" "AccountStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "roles" (
    "role_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "role_name" VARCHAR(50) NOT NULL,
    "description" VARCHAR(255) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("role_id")
);

-- CreateTable
CREATE TABLE "user_roles" (
    "user_role_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "role_id" UUID NOT NULL,
    "assigned_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_role_id")
);

-- CreateTable
CREATE TABLE "patient_profiles" (
    "patient_profile_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "date_of_birth" DATE NOT NULL,
    "gender" VARCHAR(50) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "patient_profiles_pkey" PRIMARY KEY ("patient_profile_id")
);

-- CreateTable
CREATE TABLE "doctor_profiles" (
    "doctor_profile_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "registration_number" VARCHAR(100) NOT NULL,
    "is_verified" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "doctor_profiles_pkey" PRIMARY KEY ("doctor_profile_id")
);

-- CreateTable
CREATE TABLE "health_identities" (
    "health_identity_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "patient_profile_id" UUID NOT NULL,
    "health_identity_number" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "health_identities_pkey" PRIMARY KEY ("health_identity_id")
);

-- CreateTable
CREATE TABLE "health_records" (
    "health_record_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "patient_profile_id" UUID NOT NULL,
    "uploaded_by_user_id" UUID NOT NULL,
    "record_type" "RecordType" NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "file_reference" VARCHAR(512) NOT NULL,
    "uploaded_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "health_records_pkey" PRIMARY KEY ("health_record_id")
);

-- CreateTable
CREATE TABLE "access_requests" (
    "access_request_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "doctor_profile_id" UUID NOT NULL,
    "patient_profile_id" UUID NOT NULL,
    "purpose" VARCHAR(500) NOT NULL,
    "requested_scope_type" "ConsentScope" NOT NULL DEFAULT 'ALL',
    "requested_category" "RecordType",
    "request_status" "RequestStatus" NOT NULL DEFAULT 'PENDING',
    "requested_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "access_requests_pkey" PRIMARY KEY ("access_request_id")
);

-- CreateTable
CREATE TABLE "consents" (
    "consent_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "access_request_id" UUID NOT NULL,
    "scope_type" "ConsentScope" NOT NULL DEFAULT 'ALL',
    "record_type" "RecordType",
    "status" "ConsentStatus" NOT NULL DEFAULT 'ACTIVE',
    "start_date" TIMESTAMPTZ(6) NOT NULL,
    "end_date" TIMESTAMPTZ(6) NOT NULL,
    "granted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "consents_pkey" PRIMARY KEY ("consent_id")
);

-- CreateTable
CREATE TABLE "consent_health_records" (
    "consent_health_record_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "consent_id" UUID NOT NULL,
    "health_record_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "consent_health_records_pkey" PRIMARY KEY ("consent_health_record_id")
);

-- CreateTable
CREATE TABLE "doctor_verification_requests" (
    "verification_request_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "doctor_profile_id" UUID NOT NULL,
    "reviewed_by_user_id" UUID,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "submitted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_at" TIMESTAMPTZ(6),
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "doctor_verification_requests_pkey" PRIMARY KEY ("verification_request_id")
);

-- CreateTable
CREATE TABLE "emergency_access_events" (
    "emergency_access_event_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "provider_user_id" UUID NOT NULL,
    "patient_profile_id" UUID NOT NULL,
    "justification" TEXT NOT NULL,
    "accessed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "emergency_access_events_pkey" PRIMARY KEY ("emergency_access_event_id")
);

-- CreateTable
CREATE TABLE "emergency_access_records" (
    "emergency_access_record_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "emergency_access_event_id" UUID NOT NULL,
    "health_record_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "emergency_access_records_pkey" PRIMARY KEY ("emergency_access_record_id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "audit_log_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID,
    "action_type" "AuditActionType" NOT NULL,
    "entity_type" VARCHAR(100) NOT NULL,
    "entity_id" UUID,
    "ip_address" VARCHAR(45),
    "user_agent" VARCHAR(512),
    "metadata" JSONB,
    "timestamp" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("audit_log_id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "notification_id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID NOT NULL,
    "notification_type" "NotificationType" NOT NULL,
    "message" VARCHAR(500) NOT NULL,
    "status" "NotificationStatus" NOT NULL DEFAULT 'UNREAD',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,
    "deleted_at" TIMESTAMPTZ(6),

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("notification_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "roles_role_name_key" ON "roles"("role_name");

-- CreateIndex
CREATE UNIQUE INDEX "user_roles_user_id_role_id_key" ON "user_roles"("user_id", "role_id");

-- CreateIndex
CREATE UNIQUE INDEX "patient_profiles_user_id_key" ON "patient_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "doctor_profiles_user_id_key" ON "doctor_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "doctor_profiles_registration_number_key" ON "doctor_profiles"("registration_number");

-- CreateIndex
CREATE INDEX "doctor_profiles_is_verified_idx" ON "doctor_profiles"("is_verified");

-- CreateIndex
CREATE UNIQUE INDEX "health_identities_patient_profile_id_key" ON "health_identities"("patient_profile_id");

-- CreateIndex
CREATE UNIQUE INDEX "health_identities_health_identity_number_key" ON "health_identities"("health_identity_number");

-- CreateIndex
CREATE INDEX "health_records_patient_profile_id_idx" ON "health_records"("patient_profile_id");

-- CreateIndex
CREATE INDEX "health_records_record_type_idx" ON "health_records"("record_type");

-- CreateIndex
CREATE INDEX "health_records_uploaded_at_idx" ON "health_records"("uploaded_at");

-- CreateIndex
CREATE INDEX "access_requests_doctor_profile_id_idx" ON "access_requests"("doctor_profile_id");

-- CreateIndex
CREATE INDEX "access_requests_patient_profile_id_idx" ON "access_requests"("patient_profile_id");

-- CreateIndex
CREATE INDEX "access_requests_request_status_idx" ON "access_requests"("request_status");

-- CreateIndex
CREATE UNIQUE INDEX "consents_access_request_id_key" ON "consents"("access_request_id");

-- CreateIndex
CREATE INDEX "consents_status_end_date_idx" ON "consents"("status", "end_date");

-- CreateIndex
CREATE UNIQUE INDEX "consent_health_records_consent_id_health_record_id_key" ON "consent_health_records"("consent_id", "health_record_id");

-- CreateIndex
CREATE UNIQUE INDEX "emergency_access_records_emergency_access_event_id_health_r_key" ON "emergency_access_records"("emergency_access_event_id", "health_record_id");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_idx" ON "audit_logs"("user_id");

-- CreateIndex
CREATE INDEX "audit_logs_timestamp_idx" ON "audit_logs"("timestamp");

-- CreateIndex
CREATE INDEX "notifications_user_id_status_idx" ON "notifications"("user_id", "status");

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("role_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "patient_profiles" ADD CONSTRAINT "patient_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_profiles" ADD CONSTRAINT "doctor_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_identities" ADD CONSTRAINT "health_identities_patient_profile_id_fkey" FOREIGN KEY ("patient_profile_id") REFERENCES "patient_profiles"("patient_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_records" ADD CONSTRAINT "health_records_patient_profile_id_fkey" FOREIGN KEY ("patient_profile_id") REFERENCES "patient_profiles"("patient_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_records" ADD CONSTRAINT "health_records_uploaded_by_user_id_fkey" FOREIGN KEY ("uploaded_by_user_id") REFERENCES "users"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_requests" ADD CONSTRAINT "access_requests_doctor_profile_id_fkey" FOREIGN KEY ("doctor_profile_id") REFERENCES "doctor_profiles"("doctor_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "access_requests" ADD CONSTRAINT "access_requests_patient_profile_id_fkey" FOREIGN KEY ("patient_profile_id") REFERENCES "patient_profiles"("patient_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consents" ADD CONSTRAINT "consents_access_request_id_fkey" FOREIGN KEY ("access_request_id") REFERENCES "access_requests"("access_request_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consent_health_records" ADD CONSTRAINT "consent_health_records_consent_id_fkey" FOREIGN KEY ("consent_id") REFERENCES "consents"("consent_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "consent_health_records" ADD CONSTRAINT "consent_health_records_health_record_id_fkey" FOREIGN KEY ("health_record_id") REFERENCES "health_records"("health_record_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_verification_requests" ADD CONSTRAINT "doctor_verification_requests_doctor_profile_id_fkey" FOREIGN KEY ("doctor_profile_id") REFERENCES "doctor_profiles"("doctor_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "doctor_verification_requests" ADD CONSTRAINT "doctor_verification_requests_reviewed_by_user_id_fkey" FOREIGN KEY ("reviewed_by_user_id") REFERENCES "users"("user_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emergency_access_events" ADD CONSTRAINT "emergency_access_events_provider_user_id_fkey" FOREIGN KEY ("provider_user_id") REFERENCES "users"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emergency_access_events" ADD CONSTRAINT "emergency_access_events_patient_profile_id_fkey" FOREIGN KEY ("patient_profile_id") REFERENCES "patient_profiles"("patient_profile_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emergency_access_records" ADD CONSTRAINT "emergency_access_records_emergency_access_event_id_fkey" FOREIGN KEY ("emergency_access_event_id") REFERENCES "emergency_access_events"("emergency_access_event_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emergency_access_records" ADD CONSTRAINT "emergency_access_records_health_record_id_fkey" FOREIGN KEY ("health_record_id") REFERENCES "health_records"("health_record_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;
