# ANUJNA – Database Architecture Review Report (v1.0)

**Document ID:** ANJ-DBR-v1.0  
**Project:** ANUJNA – Consent-Driven Unified Health Identity Platform  
**Status:** Approved and Signed-off  
**Approval Date:** 2026-06-14  
**Target Schema Engine:** PostgreSQL + Prisma ORM  

---

### 🏛️ Sign-off Decision Log:
* **Approved Refinements:** REF-001 (Consent.record_type), REF-003 (AccessRequest.requested_scope_type/requested_category), REF-005 (AuditLog client context fields).
* **Deferred Refinements (Phase 2):** REF-004 (is_emergency_accessible boolean flag), REF-006 (Composite PKs for junction tables - surrogate keys kept for MVP simplicity).
* **Core MVP Design Decision:** Proactive consent is out of scope. All Consent records must originate from an AccessRequest (access_request_id is non-nullable). Redundant patient/doctor foreign keys are removed from the Consent table.

---

## 1. Executive Summary

This report presents a final database architecture review of the **ANUJNA** platform prior to generating the Prisma schema. The objective of this review is to ensure that the relational schema defined in the **Logical Database Design (LDD) v1.0** is fully complete, logically sound, compliant with system requirements (SRS v1.0), supportive of access controls (RBAC Matrix v1.1), and optimized for PostgreSQL and Prisma ORM.

The review indicates that the core database design is highly structured, maintains Third Normal Form (3NF) compliance, and aligns well with the platform's patient-centric design goals. However, we have identified **six key architectural gaps** and **several normalization/index optimizations** that must be resolved to ensure robust consent enforcement, audit compliance, and update integrity.

---

## 2. Entity Completeness Review

We validated the 15 entities defined in the LDD against the core Domain Model:

1. **`User`**: Base identity for authentication. Complete.
2. **`Role`**: Role definitions (Patient, Doctor, Admin, Auditor, Lab Staff, Emergency Provider). Complete.
3. **`UserRole`**: Junction table for user-role relationships. Complete.
4. **`PatientProfile`**: Demographic attributes specific to patients. Complete.
5. **`DoctorProfile`**: Professional registry attributes specific to doctors. Complete.
6. **`HealthIdentity`**: Separated entity for the unique health identifier. Complete.
7. **`HealthRecord`**: Document metadata and references. Complete.
8. **`AccessRequest`**: Doctor requests to access records. Complete.
9. **`Consent`**: Patient authorization rules. Complete.
10. **`ConsentHealthRecord`**: Junction table for record-level consent. Complete.
11. **`DoctorVerificationRequest`**: Onboarding approval trail. Complete.
12. **`EmergencyAccessEvent`**: Log of emergency override events. Complete.
13. **`EmergencyAccessRecord`**: Junction table for emergency-accessed records. Complete.
14. **`AuditLog`**: Immutable security trail. Complete.
15. **`Notification`**: User communications log. Complete.

### Design Observations:
* **No profile tables for administrative, audit, or lab staff:** These roles are successfully supported purely through the RBAC model (`UserRole` mapping to `Role`). Since they do not have distinct domain-specific properties beyond base user attributes (unlike patients who need DOB/gender, or doctors who need registration numbers), this is a clean, minimal design that avoids unnecessary tables.

---

## 3. Relationships & Cardinality Validation

We reviewed the cardinalities and foreign key setups. The primary mappings are correct:
* **`User` ↔ `PatientProfile` / `DoctorProfile` (1:0..1):** Enforced correctly via unique constraints on `user_id` in the profile tables.
* **`PatientProfile` ↔ `HealthIdentity` (1:1):** Enforced correctly via unique constraints on `patient_profile_id` and `health_identity_number`.
* **`PatientProfile` ↔ `HealthRecord` (1:N):** Enforced correctly via `patient_profile_id` on `HealthRecord`.
* **`Consent` ↔ `HealthRecord` (M:N):** Correctly resolved via the `ConsentHealthRecord` junction table.
* **`EmergencyAccessEvent` ↔ `HealthRecord` (M:N):** Correctly resolved via the `EmergencyAccessRecord` junction table.

---

## 4. Workflows & Requirement Validation

### 4.1 RBAC Support
The design supports the RBAC Matrix perfectly by separating users and roles via `UserRole`. Dynamic permission validation can be performed in the application layer by checking the user's role memberships.

### 4.2 Consent Workflows
The schema maps the transition from an `AccessRequest` to a `Consent` grant:
* An `AccessRequest` is submitted by a doctor.
* If approved, a `Consent` record is created, referencing `access_request_id`.
* The `ConsentHealthRecord` junction table maps the individual files approved under that consent.
* **Architectural Issue identified:** Storing both category-level and record-level consents is required by the SRS, but the schema has a gap regarding category storage (see Section 5.1).

### 4.3 Emergency Workflows
The schema supports emergency overrides:
* `EmergencyAccessEvent` captures the provider, patient, justification, and timestamp.
* `EmergencyAccessRecord` logs exactly which records were opened during the emergency session.
* **Architectural Issue identified:** Predefined emergency scopes cannot be checked at the DB level (see Section 5.3).

### 4.4 Audit Requirements
The `AuditLog` table records the actor, action type, target entity, and timestamp, meeting the immutability requirements.
* **Refinement Recommended:** Capturing client context is necessary for compliance (see Section 5.5).

---

## 5. Identified Gaps & Refinements

We have identified the following gaps that should be refined before the Prisma schema is generated.

### 5.1 Gap 1: Missing Record Category in Consent (Critical)
* **Context:** SRS `FR-023` requires the system to support consent for healthcare record categories (e.g., granting access only to `LAB_REPORT` or `PRESCRIPTION`).
* **Problem:** The `Consent` table contains a `scope_type` (Enum: `ALL`, `CATEGORY`, `INDIVIDUAL`) but lacks a field to store *which* category is authorized.
* **Impact:** If `scope_type` is set to `CATEGORY`, the system has no way to store or evaluate which record type the doctor is allowed to access.
* **Recommendation:** Add a nullable `record_type` attribute to the `Consent` table matching the Enum used in `HealthRecord.record_type`.

### 5.2 Gap 2: Redundant Doctor/Patient Foreign Keys in Consent
* **Context:** In LDD, the `Consent` table contains `access_request_id` (Unique FK to `AccessRequest`), `patient_profile_id`, and `doctor_profile_id`.
* **Problem:** If a consent is *always* generated in response to an access request (as per Use Case preconditions), having `patient_profile_id` and `doctor_profile_id` directly in the `Consent` table is redundant and risks update anomalies (e.g., a consent record pointing to a different patient than the linked access request).
* **Nuance:** If the patient is allowed to proactively grant consent *without* an access request, then `access_request_id` is nullable, and the profile IDs are required.
* **Recommendation:** 
  * If proactive consent is supported, mark `access_request_id` as nullable and write application-level checks to ensure patient/doctor IDs match when `access_request_id` is present.
  * If all consent must originate from requests, remove `patient_profile_id` and `doctor_profile_id` from `Consent`, making `access_request_id` the mandatory unique relation from which patient/doctor profiles are derived.

### 5.3 Gap 3: Missing Requested Scope in AccessRequest
* **Context:** During the Doctor Access Workflow (`UC-020`), the doctor specifies the requested scope (e.g., "Requesting access to Laboratory Reports only").
* **Problem:** The `AccessRequest` table has no field to store what scope or category the doctor is requesting.
* **Impact:** The patient receives a notification but cannot see what files or categories the doctor is seeking access to during the review phase (`UC-024`).
* **Recommendation:** Add a `requested_scope_type` (Enum: `ALL`, `CATEGORY`, `INDIVIDUAL`) and a nullable `requested_category` (Enum matching `record_type`) to the `AccessRequest` table.

### 5.4 Gap 4: Missing Emergency Scope Flag on HealthRecord
* **Context:** SRS `FR-050` states the system must enforce predefined emergency access scope restrictions.
* **Problem:** The system has no way of knowing which health records are included in the emergency access scope.
* **Impact:** Without a structural indicator, an emergency access event would have to either block all records or allow access to the patient's entire medical history, violating the least-privilege override principle (`DP-06`).
* **Recommendation:** Add an `is_emergency_accessible` (Boolean, default: `false`) flag to `HealthRecord`. This empowers patients to flag specific records (e.g., allergies list, critical medical summaries) as emergency-accessible. Alternatively, hardcode in application logic that only specific record types (e.g., `DISCHARGE_SUMMARY`) are accessible. A database flag is highly recommended for patient-centric control.

### 5.5 Gap 5: Audit Log Metadata Enrichment
* **Context:** For strict compliance and auditability, audit logs must capture context to assist in forensic investigation (`UC-034`).
* **Problem:** The `AuditLog` table lacks attributes for network or client headers.
* **Recommendation:** Add nullable `ip_address` (String), `user_agent` (String), and `metadata` (JSON) columns to `AuditLog`.

### 5.6 Gap 6: Surrogate Keys on Junction Tables (Optimization)
* **Context:** Junction tables `UserRole`, `ConsentHealthRecord`, and `EmergencyAccessRecord` use surrogate primary keys (`user_role_id`, etc.).
* **Problem:** In relational databases and Prisma ORM, using composite primary keys (e.g., `@@id([user_id, role_id])` for `UserRole`) is more natural, enforces uniqueness automatically at the schema level, and reduces index storage overhead.
* **Recommendation:** Remove `user_role_id`, `consent_health_record_id`, and `emergency_access_record_id`, replacing them with composite primary keys.

---

## 6. Schema Normalization & PostgreSQL Mapping

* **3NF Compliance:** The schema is fully compliant with Third Normal Form (3NF). Core demographic data is in `PatientProfile`/`DoctorProfile`, authentication data is in `User`, and audit trails are separated.
* **UUID Implementation:** We recommend using `UUID` for all surrogate primary keys across all tables (instead of auto-incrementing integers) to prevent ID enumeration vulnerabilities, which is critical for health platforms.
* **Enums Map:** The following enums should be explicitly defined in PostgreSQL:
  * `AccountStatus` (`ACTIVE`, `SUSPENDED`, `INACTIVE`)
  * `VerificationStatus` (`PENDING`, `APPROVED`, `REJECTED`)
  * `RecordType` (`LAB_REPORT`, `PRESCRIPTION`, `DIAGNOSTIC_REPORT`, `DISCHARGE_SUMMARY`, `VACCINATION_RECORD`)
  * `RequestStatus` (`PENDING`, `APPROVED`, `REJECTED`, `EXPIRED`)
  * `ConsentScope` (`ALL`, `CATEGORY`, `INDIVIDUAL`)
  * `ConsentStatus` (`ACTIVE`, `REVOKED`, `EXPIRED`)
  * `NotificationType` (`ACCESS_REQUEST`, `CONSENT_GRANTED`, `CONSENT_REVOKED`, `EMERGENCY_ACCESS`, `VERIFICATION_STATUS`)
  * `AuditActionType` (`LOGIN`, `LOGOUT`, `RECORD_VIEW`, `CONSENT_GRANTED`, `CONSENT_REVOKED`, `EMERGENCY_ACCESS`, `VERIFICATION_APPROVED`, `VERIFICATION_REJECTED`)

---

## 7. Indexing Strategy

To maintain sub-2-second API latencies (SRS `NFR-006` and `NFR-007`), we recommend the following indexing plan:

* **`User`**: Unique index on `email` (for login lookup).
* **`DoctorProfile`**: Unique index on `registration_number`.
* **`HealthIdentity`**: Unique index on `health_identity_number` (for doctor lookups).
* **`HealthRecord`**: Index on `patient_profile_id` (for patient dashboard retrieval).
* **`AccessRequest`**: Indexes on `patient_profile_id` (for patient approval page) and `doctor_profile_id` (for doctor dashboard).
* **`Consent`**: Indexes on `doctor_profile_id` and `end_date` (for evaluating active record sharing authorization).
* **`AuditLog`**: Indexes on `user_id` and `timestamp` (for auditor search queries).

---

## 8. Refinement Recommendations Summary

| Refinement Code | Target Entity | Proposed Action | Reason |
| :--- | :--- | :--- | :--- |
| **REF-001** | `Consent` | Add `record_type` (Enum, Nullable) | Enables category-level consent (FR-023). |
| **REF-002** | `Consent` | Make `access_request_id` Nullable | Allows proactive consent without access requests, if required; otherwise, remove patient/doctor IDs from `Consent` if all consents must link to requests. |
| **REF-003** | `AccessRequest` | Add `requested_scope_type` (Enum) & `requested_category` (Enum, Nullable) | Allows patient to review the requested scope during approval. |
| **REF-004** | `HealthRecord` | Add `is_emergency_accessible` (Boolean, default `false`) | Supports patient-driven emergency access scope definition. |
| **REF-005** | `AuditLog` | Add `ip_address`, `user_agent`, and `metadata` (JSON) | Enriches audit records for compliance investigations. |
| **REF-006** | Junction Tables | Replace surrogate keys with composite primary keys | Optimizes junction tables (`UserRole`, `ConsentHealthRecord`, `EmergencyAccessRecord`) in PostgreSQL and Prisma. |

---

## 9. Conclusion & Action Plan

This database design is structurally sound and ready for Prisma schema implementation subject to resolving the gaps highlighted in this report. 

### Recommended Next Steps:
1. **User Review:** Align on whether proactive consent is supported (influences REF-002) and whether patient-driven emergency flags are desired (influences REF-004).
2. **Database Sign-off:** User provides formal approval on the refined architecture.
3. **Prisma Generation:** Proceed with creating `schema.prisma` mapping the refined physical model.
