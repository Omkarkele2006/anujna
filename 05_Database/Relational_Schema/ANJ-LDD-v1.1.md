# ANUJNA Logical Database Design v1.1

**Document ID:** ANJ-LDD-v1.1  
**Project:** ANUJNA – Consent-Driven Unified Health Identity Platform  
**Status:** Approved Design Baseline  
**Database Target:** PostgreSQL  
**ORM Target:** Prisma ORM  

---

## 1. Design Objectives

The logical database model shall:
1. Support PostgreSQL relational schemas.
2. Support Prisma ORM mapping conventions.
3. Maintain Third Normal Form (3NF) compliance to prevent update/delete anomalies.
4. Support the Role-Based Access Control (RBAC) Matrix v1.1.
5. Support the consent-driven record sharing workflow (with all consents tied to doctor access requests).
6. Support audit trails enriched with client contextual information (IP address, user agent, metadata).
7. Support emergency exception access workflows.
8. Enforce strong data types (UUIDs for primary/foreign keys, precise datetime timestamps, strict Enums).

---

## 2. Entity Specifications

All primary keys (`PK`) and foreign keys (`FK`) use the `UUID` data type to prevent ID enumeration attacks unless specified otherwise.

### 2.1 User
Represents any authenticated participant within the platform (Patient, Doctor, Admin, Auditor, Lab Staff, Emergency Provider).

* **Primary Key:** `user_id` (UUID)
* **Attributes:**

| Attribute | Type | Nullability | Constraints / Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `user_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `full_name` | String | Non-Nullable | - | Full display name. |
| `email` | String | Non-Nullable | Unique | Login credential. |
| `password_hash` | String | Non-Nullable | - | Cryptographically hashed password. |
| `account_status` | Enum | Non-Nullable | Default: `ACTIVE` | User status: `ACTIVE`, `SUSPENDED`, `INACTIVE`. |
| `created_at` | Timestamp | Non-Nullable | Default: Current Time | Timestamp of registration. |
| `updated_at` | Timestamp | Non-Nullable | Default: Current Time | Timestamp of last modification. |

* **Unique Constraints:** `email`
* **Business Constraints:** Email must be unique. Suspended users are restricted from protected workflows.

---

### 2.2 Role
Represents a collection of permissions that define system access rights.

* **Primary Key:** `role_id` (UUID)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `role_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `role_name` | String | Non-Nullable | Unique | Name of the role (e.g., `Patient`, `Doctor`). |
| `description` | String | Non-Nullable | - | Short description of the role's purpose. |

* **Unique Constraints:** `role_name`

---

### 2.3 UserRole (Junction Table)
Associates users with assigned roles (resolves many-to-many relationship).

* **Primary Key:** `user_role_id` (UUID) - *Surrogate key retained for MVP simplicity.*
* **Foreign Keys:**
  * `user_id` → `User(user_id)` (ON DELETE CASCADE)
  * `role_id` → `Role(role_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `user_role_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `user_id` | UUID | Non-Nullable | FK | Reference to the user. |
| `role_id` | UUID | Non-Nullable | FK | Reference to the assigned role. |
| `assigned_at` | Timestamp | Non-Nullable | Default: Current Time | When the role was assigned. |

* **Unique Constraints:** `(user_id, role_id)` (prevents duplicate role assignments)

---

### 2.4 PatientProfile
Demographic attributes specific to patients.

* **Primary Key:** `patient_profile_id` (UUID)
* **Foreign Keys:**
  * `user_id` → `User(user_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `patient_profile_id`| UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `user_id` | UUID | Non-Nullable | FK, Unique | Link to base User record. |
| `date_of_birth` | Date | Non-Nullable | - | Patient's date of birth. |
| `gender` | String | Non-Nullable | - | Patient's gender. |

* **Unique Constraints:** `user_id` (guarantees a User has at most one Patient profile)

---

### 2.5 DoctorProfile
Registry and verification attributes specific to doctors.

* **Primary Key:** `doctor_profile_id` (UUID)
* **Foreign Keys:**
  * `user_id` → `User(user_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `doctor_profile_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `user_id` | UUID | Non-Nullable | FK, Unique | Link to base User record. |
| `registration_number`| String | Non-Nullable | Unique | Professional medical registration ID. |
| `verification_status`| Enum | Non-Nullable | Default: `PENDING` | Status: `PENDING`, `APPROVED`, `REJECTED`. |

* **Unique Constraints:** `user_id`, `registration_number`

---

### 2.6 HealthIdentity
Represents a unique patient healthcare identifier, separate from base profile columns for pseudonymization and future interoperability.

* **Primary Key:** `health_identity_id` (UUID)
* **Foreign Keys:**
  * `patient_profile_id` → `PatientProfile(patient_profile_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `health_identity_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `patient_profile_id` | UUID | Non-Nullable | FK, Unique | Link to PatientProfile. |
| `health_identity_number`| String | Non-Nullable | Unique | ANUJNA Health ID (e.g. `ANJ26A7F92K4Q1`). |
| `created_at` | Timestamp | Non-Nullable | Default: Current Time | Generation timestamp. |

* **Unique Constraints:** `patient_profile_id`, `health_identity_number`

---

### 2.7 HealthRecord
Metadata and storage file references for patient medical documents.

* **Primary Key:** `health_record_id` (UUID)
* **Foreign Keys:**
  * `patient_profile_id` → `PatientProfile(patient_profile_id)` (ON DELETE CASCADE)
  * `uploaded_by_user_id` → `User(user_id)` (ON DELETE RESTRICT)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `health_record_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `patient_profile_id` | UUID | Non-Nullable | FK | Reference to the patient owner. |
| `uploaded_by_user_id`| UUID | Non-Nullable | FK | User who performed the upload. |
| `record_type` | Enum | Non-Nullable | - | Type: `LAB_REPORT`, `PRESCRIPTION`, `DIAGNOSTIC_REPORT`, `DISCHARGE_SUMMARY`, `VACCINATION_RECORD`. |
| `title` | String | Non-Nullable | - | Document title. |
| `file_reference` | String | Non-Nullable | - | Reference to secure object storage path. |
| `uploaded_at` | Timestamp | Non-Nullable | Default: Current Time | Upload timestamp. |

* **Business Constraints:** Only patients or authorized actors (like Laboratory Staff) can upload records.

---

### 2.8 AccessRequest
Stores access requests submitted by doctors to view patient records.

* **Primary Key:** `access_request_id` (UUID)
* **Foreign Keys:**
  * `doctor_profile_id` → `DoctorProfile(doctor_profile_id)` (ON DELETE CASCADE)
  * `patient_profile_id` → `PatientProfile(patient_profile_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `access_request_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `doctor_profile_id` | UUID | Non-Nullable | FK | Doctor submitting the request. |
| `patient_profile_id` | UUID | Non-Nullable | FK | Patient whose records are requested. |
| `purpose` | String | Non-Nullable | - | Medical reason/purpose for request. |
| `requested_scope_type`| Enum | Non-Nullable | Default: `ALL` | Scope: `ALL`, `CATEGORY`, `INDIVIDUAL` *(REF-003)*. |
| `requested_category` | Enum | Nullable | - | Target `RecordType` if scope is `CATEGORY` *(REF-003)*. |
| `request_status` | Enum | Non-Nullable | Default: `PENDING` | Status: `PENDING`, `APPROVED`, `REJECTED`, `EXPIRED`. |
| `requested_at` | Timestamp | Non-Nullable | Default: Current Time | Submission timestamp. |

* **Business Constraints:** Only verified doctors (`verification_status == APPROVED`) can submit access requests.

---

### 2.9 Consent
Represents active patient authorization granting a doctor permission to view health records.

* **Primary Key:** `consent_id` (UUID)
* **Foreign Keys:**
  * `access_request_id` → `AccessRequest(access_request_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `consent_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `access_request_id` | UUID | Non-Nullable | FK, Unique | Mandatory link to approved `AccessRequest` *(REF-002 Decision)*. |
| `scope_type` | Enum | Non-Nullable | Default: `ALL` | Scope: `ALL`, `CATEGORY`, `INDIVIDUAL`. |
| `record_type` | Enum | Nullable | - | Target `RecordType` if scope is `CATEGORY` *(REF-001)*. |
| `status` | Enum | Non-Nullable | Default: `ACTIVE` | Status: `ACTIVE`, `REVOKED`, `EXPIRED`. |
| `start_date` | Timestamp | Non-Nullable | - | Start of validity period. |
| `end_date` | Timestamp | Non-Nullable | - | Expiration of validity period. |
| `granted_at` | Timestamp | Non-Nullable | Default: Current Time | When the consent was recorded. |

* **Unique Constraints:** `access_request_id` (maintains a strict 1:0..1 cardinality; one access request has at most one consent).
* **Normalization (REF-002 Update):** Redundant fields `patient_profile_id` and `doctor_profile_id` have been removed since they are already captured in the parent `AccessRequest` and can be retrieved via relations.
* **Business Constraints:** `end_date` must be greater than `start_date`. Once revoked or expired, consent status changes and access is denied.

---

### 2.10 ConsentHealthRecord (Junction Table)
Resolves the many-to-many relationship between `Consent` and specific individual `HealthRecord` documents when `scope_type == INDIVIDUAL`.

* **Primary Key:** `consent_health_record_id` (UUID) - *Surrogate key retained for MVP simplicity.*
* **Foreign Keys:**
  * `consent_id` → `Consent(consent_id)` (ON DELETE CASCADE)
  * `health_record_id` → `HealthRecord(health_record_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `consent_health_record_id`| UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `consent_id` | UUID | Non-Nullable | FK | Associated consent record. |
| `health_record_id` | UUID | Non-Nullable | FK | Associated health record. |

* **Unique Constraints:** `(consent_id, health_record_id)` (prevents duplicate mappings)

---

### 2.11 DoctorVerificationRequest
Audit log of doctor credentials reviews by administrators.

* **Primary Key:** `verification_request_id` (UUID)
* **Foreign Keys:**
  * `doctor_profile_id` → `DoctorProfile(doctor_profile_id)` (ON DELETE CASCADE)
  * `reviewed_by_user_id` → `User(user_id)` (ON DELETE SET NULL)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `verification_request_id`| UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `doctor_profile_id` | UUID | Non-Nullable | FK | Doctor being verified. |
| `reviewed_by_user_id` | UUID | Nullable | FK | Admin user who reviewed. |
| `status` | Enum | Non-Nullable | Default: `PENDING` | Status: `PENDING`, `APPROVED`, `REJECTED`. |
| `submitted_at` | Timestamp | Non-Nullable | Default: Current Time | When requested. |
| `reviewed_at` | Timestamp | Nullable | - | When reviewed. |

---

### 2.12 EmergencyAccessEvent
Tracks emergency healthcare information access overrides initiated by Emergency Providers.

* **Primary Key:** `emergency_access_event_id` (UUID)
* **Foreign Keys:**
  * `provider_user_id` → `User(user_id)` (ON DELETE RESTRICT)
  * `patient_profile_id` → `PatientProfile(patient_profile_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `emergency_access_event_id`| UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `provider_user_id` | UUID | Non-Nullable | FK | Emergency provider user. |
| `patient_profile_id` | UUID | Non-Nullable | FK | Affected patient profile. |
| `justification` | String | Non-Nullable | - | Text justification for the override. |
| `accessed_at` | Timestamp | Non-Nullable | Default: Current Time | Override timestamp. |

* **Business Constraints:** Justification is mandatory and must be logged. Emergency session duration is governed in application logic.

---

### 2.13 EmergencyAccessRecord (Junction Table)
Tracks the specific list of patient healthcare records accessed by the provider during an emergency event (resolves many-to-many relationship).

* **Primary Key:** `emergency_access_record_id` (UUID) - *Surrogate key retained for MVP simplicity.*
* **Foreign Keys:**
  * `emergency_access_event_id` → `EmergencyAccessEvent(emergency_access_event_id)` (ON DELETE CASCADE)
  * `health_record_id` → `HealthRecord(health_record_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `emergency_access_record_id`| UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `emergency_access_event_id` | UUID | Non-Nullable | FK | Associated emergency event. |
| `health_record_id` | UUID | Non-Nullable | FK | Associated health record. |

* **Unique Constraints:** `(emergency_access_event_id, health_record_id)` (prevents duplicate logs)

---

### 2.14 AuditLog
Stores tamper-evident records of sensitive system activities.

* **Primary Key:** `audit_log_id` (UUID)
* **Foreign Keys:**
  * `user_id` → `User(user_id)` (ON DELETE SET NULL)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `audit_log_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `user_id` | UUID | Nullable | FK | User who initiated action. |
| `action_type` | Enum | Non-Nullable | - | Action (e.g. `LOGIN`, `RECORD_VIEW`). |
| `entity_type` | String | Non-Nullable | - | Affected table name (e.g. `HealthRecord`).|
| `entity_id` | UUID | Nullable | - | Primary key of affected record. |
| `ip_address` | String | Nullable | - | Client IP address *(REF-005)*. |
| `user_agent` | String | Nullable | - | Client browser / user agent *(REF-005)*.|
| `metadata` | JSON | Nullable | - | Auxiliary request parameters *(REF-005)*.|
| `timestamp` | Timestamp | Non-Nullable | Default: Current Time | Action timestamp. |

* **Business Constraints:** Audit logs must be append-only and immutable. No update or delete operations are permitted.

---

### 2.15 Notification
Tracks system alerts for users (e.g., access request alerts, consent revocations).

* **Primary Key:** `notification_id` (UUID)
* **Foreign Keys:**
  * `user_id` → `User(user_id)` (ON DELETE CASCADE)
* **Attributes:**

| Attribute | Type | Nullability | Constraints | Description |
| :--- | :--- | :--- | :--- | :--- |
| `notification_id` | UUID | Non-Nullable | PK, Default: UUID Gen | Unique identifier. |
| `user_id` | UUID | Non-Nullable | FK | User receiving notification. |
| `notification_type` | Enum | Non-Nullable | - | Type (e.g. `ACCESS_REQUEST`). |
| `message` | String | Non-Nullable | - | Alert message content. |
| `status` | Enum | Non-Nullable | Default: `UNREAD` | Read status: `UNREAD`, `READ`. |
| `created_at` | Timestamp | Non-Nullable | Default: Current Time | Alert timestamp. |

---

## 3. Junction Tables Summary

The schema uses three explicit junction tables to map many-to-many (M:N) relationships, utilizing surrogate PKs for mapping simplicity:

| Table Name | Entity 1 | Entity 2 | Unique Composite Constraint | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`UserRole`** | `User` | `Role` | `(user_id, role_id)` | Maps multi-role memberships for users. |
| **`ConsentHealthRecord`** | `Consent` | `HealthRecord` | `(consent_id, health_record_id)` | Maps specific files included in record-level consent. |
| **`EmergencyAccessRecord`**| `EmergencyAccessEvent`| `HealthRecord` | `(emergency_access_event_id, health_record_id)` | Records files accessed during an emergency. |

---

## 4. Candidate Indexes

To meet latency requirements (under 2 seconds for API routing, 3 seconds for record fetching), the following database indexes are defined:

1. **`User`**: Unique Index on `email` (login queries).
2. **`DoctorProfile`**: Unique Index on `registration_number` (verification lookup).
3. **`HealthIdentity`**: Unique Index on `health_identity_number` (patient searches by Doctor).
4. **`HealthRecord`**: Index on `patient_profile_id` (dashboard retrieval).
5. **`AccessRequest`**:
   * Index on `patient_profile_id` (patient approval lists).
   * Index on `doctor_profile_id` (doctor request tracking).
6. **`Consent`**:
   * Unique Index on `access_request_id` (one-to-one mapping enforcement).
   * Composite Index on `(status, end_date)` (routine automated checks for expirations).
7. **`AuditLog`**:
   * Index on `user_id` (auditing active users).
   * Index on `timestamp` (forensic timeline ordering).
8. **`Notification`**: Index on `(user_id, status)` (fetching unread notices).

---

## 5. Derived Relationships

As all consents are now required to originate from an access request, the following relationships are derived dynamically rather than stored redundantly:

$$\text{Consent} \rightarrow \text{AccessRequest} \rightarrow \text{PatientProfile}$$
$$\text{Consent} \rightarrow \text{AccessRequest} \rightarrow \text{DoctorProfile}$$

When evaluating a doctor's permission to view a patient's record:
1. Locate active `Consent` where current time falls within `[start_date, end_date]` and status is `ACTIVE`.
2. Jointly check that the `AccessRequest` linked to this consent matches the querying `doctor_profile_id` and the owner `patient_profile_id`.
3. If `scope_type == ALL`, permit view.
4. If `scope_type == CATEGORY`, check if `HealthRecord.record_type == Consent.record_type`.
5. If `scope_type == INDIVIDUAL`, check if a row exists in `ConsentHealthRecord` mapping `(consent_id, health_record_id)`.

---

## 6. Redundant Attributes Removed

To eliminate insertion and update anomalies, the following data attributes are derived dynamically through relational joins:

1. **Patient and Doctor Profile IDs in `Consent`:**  
   * *Reason:* Already present in the associated `AccessRequest`. Storing them in `Consent` is redundant.
2. **Patient Name and Doctor Name in `Consent` / `AccessRequest`:**  
   * *Reason:* Readily derivable via Joins to `PatientProfile` / `DoctorProfile` and `User`.
3. **HealthIdentity Number in `Consent` / `AccessRequest`:**  
   * *Reason:* Derivable via `PatientProfile` → `HealthIdentity`.
4. **Authorized Record Count in `Consent`:**  
   * *Reason:* Can be aggregated directly via `COUNT` queries on `ConsentHealthRecord`.

---

## 7. Normalization Review

* **First Normal Form (1NF):** All columns contain atomic values. No repeating fields or multi-valued cells exist.
* **Second Normal Form (2NF):** Satisfied. All tables have primary keys, and all non-key columns depend on the complete primary key.
* **Third Normal Form (3NF):** Satisfied. No transitive functional dependencies exist. User attributes are isolated from profiles, profiles are isolated from audit and consent records, and consent mappings are separated from record uploads.
