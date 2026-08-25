# Kao Authentication & Authorization Contract

## 1. Purpose

กำหนด Contract ระหว่าง Kao ID
และระบบที่ต้องการใช้ Identity ของผู้ใช้งาน

รวมถึง:

- Authentication
- Authorization
- User Identity
- Agent Identity
- Session
- Token
- Permission
- Scope
- Role
- Audit

เอกสารนี้เป็น Specification
ยังไม่ใช่ Implementation

---

# 2. Core Principle

Kao ID มีหน้าที่หลัก:

Authentication

และเป็น Identity Provider
สำหรับ Kao Ecosystem

Kao Brain มีหน้าที่หลัก:

Authorization
+
Context
+
Project Access

ดังนั้น:

Kao ID
=
Who are you?

Kao Brain
=
What are you allowed to do?

---

# 3. Identity Flow

Human User

↓

Kao ID

↓

Authentication

↓

Identity Token

↓

Kao Brain

↓

Authorization

↓

Permission + Scope

↓

Resource Access

---

# 4. Human Identity

Human User ต้องมี:

- user_id
- identity_status
- authentication_status

Kao ID เป็น Source of Truth
สำหรับ Identity ของ Human

Kao Brain ไม่ควรสร้าง Human Identity ซ้ำ
โดยไม่มี Reference ไปยัง Kao ID

---

# 5. Kao ID

Kao ID เป็น Identity Layer

สามารถทำหน้าที่:

- User Registration
- Authentication
- Identity Verification
- Session Identity
- Identity Token
- Account Status

รายละเอียด Identity Policy
ต้องอยู่ใน Kao ID Documentation

---

# 6. Identity ID

Kao ID ต้องมี Identifier
ที่สามารถใช้เป็น External Identity Reference

ตัวอย่าง:

kao_user_id

Kao Brain ใช้ Identifier นี้
เพื่อเชื่อม User กับ Project

---

# 7. Authentication

Authentication ต้องเกิดที่:

Kao ID

หรือ

Authorized Identity Provider

Kao Brain ไม่ควรรับ:

- User Password
- Password Hash
- MFA Secret

โดยตรง

---

# 8. Token

หลัง Authentication
Kao ID สามารถออก Token

Token ต้องมีข้อมูลขั้นต่ำที่จำเป็น
สำหรับการ Authorization

ตัวอย่าง Claims:

- sub
- issuer
- audience
- issued_at
- expires_at

และอาจมี:

- session_id
- identity_status
- verification_level

ตามความเหมาะสม

---

# 9. Token Validation

Kao Brain ต้องตรวจ:

- Signature
- Issuer
- Audience
- Expiration
- Token Status
- Required Claims

ห้ามเชื่อข้อมูลจาก Client
โดยไม่ตรวจ Token

---

# 10. Token Audience

Token สำหรับ Kao Brain
ควรมี Audience ที่ระบุชัดเจน

ตัวอย่าง:

aud:

kao-brain

Token ที่ออกให้ Service อื่น
ไม่ควรถูกนำมาใช้กับ Kao Brain
โดยไม่มีการตรวจสอบ

---

# 11. Session

Session ต้องมี:

- session_id
- user_id
- created_at
- expires_at
- revoked_at
- status

Status:

- active
- expired
- revoked

---

# 12. Session Revocation

หาก User:

- Logout
- Account Disabled
- Security Event
- Credential Compromise

Session สามารถถูก Revoke

Kao Brain ต้องเคารพ Session Status
ตาม Integration Policy

---

# 13. Authorization

หลัง Authentication

Kao Brain ต้องตรวจ:

1. User Identity
2. Project Membership
3. Role
4. Permission
5. Resource
6. Scope
7. Environment
8. Approval หากจำเป็น

---

# 14. Project Membership

User ต้องมี Membership
ก่อนเข้าถึง Project

ตัวอย่าง:

user_id

↓

project_membership

↓

project_id

---

# 15. Project Roles

ตัวอย่าง Role:

- Owner
- Admin
- Manager
- Developer
- Reviewer
- Viewer

Role เป็นตัวกำหนดสิทธิ์ระดับ Project

---

# 16. Permission

Permission เป็นสิทธิ์เฉพาะ Action

ตัวอย่าง:

PROJECT_READ

PROJECT_WRITE

TASK_READ

TASK_WRITE

DECISION_READ

DECISION_PROPOSE

DECISION_APPROVE

PROPOSAL_CREATE

PROPOSAL_APPROVE

EXECUTION_RUN

AUDIT_READ

---

# 17. Scope

Permission ต้องสามารถจำกัด Scope

ตัวอย่าง:

Permission:

TASK_WRITE

Scope:

project:KAO-001

หรือ:

project:KAO-001/feature:identity

---

# 18. Least Privilege

User หรือ Agent
ควรได้รับเฉพาะ Permission
ที่จำเป็นต่อหน้าที่

ไม่ใช้:

ADMIN

เป็น Default

---

# 19. Owner

Project Owner สามารถ:

- Manage Project
- Manage Members
- Approve Project Decisions
- Manage Project Settings

แต่ High Risk Operations
ยังต้องปฏิบัติตาม Security Policy

---

# 20. Admin

Admin สามารถจัดการ:

- Members
- Roles
- Permissions
- Project Configuration

แต่ไม่ควรสามารถอ่าน Secret
หากไม่จำเป็นต่อหน้าที่

---

# 21. Agent Identity

AI Agent ไม่ใช่ Human User

Agent ต้องมี:

- agent_id
- agent_key
- status
- role
- permission
- scope

---

# 22. Human → Agent Authorization

Human User สามารถมอบหมายงาน
ให้ AI Agent

Flow:

Human

↓

Kao ID

↓

Authorization

↓

Agent Assignment

↓

Task

↓

Agent Execution

---

# 23. Agent Authentication

Agent ต้อง Authenticate
ด้วย Agent Credential

ไม่ใช้:

Human Password

แทน Agent Identity

---

# 24. Agent Authorization

ก่อน Agent Execute

Kao Brain ต้องตรวจ:

- agent_id
- task_id
- permission
- scope
- environment
- approval

---

# 25. Approval Boundary

High Risk Action
ต้องมี Approval

ตัวอย่าง:

- Identity Change
- Authentication Change
- Authorization Change
- Payment
- KYC
- Database
- Production
- Data Deletion

---

# 26. Approval Ownership

Approval ต้องมาจาก:

Authorized Human

ไม่ใช่:

AI Agent

---

# 27. Authorization Decision

Authorization Engine ต้องตอบ:

ALLOW

หรือ

DENY

ไม่ควรมีสถานะคลุมเครือ

---

# 28. Deny by Default

ถ้าไม่พบ Permission:

DENY

ไม่ใช่:

ALLOW

---

# 29. Resource Authorization

ตัวอย่าง:

User A

มี:

TASK_READ

Project A

แต่ไม่มี:

TASK_READ

Project B

Request:

GET /projects/project-b/tasks

ผล:

DENY

---

# 30. Object-Level Authorization

การมี Permission:

TASK_READ

ไม่ได้หมายความว่าอ่าน Task ทุกตัวได้

ต้องตรวจ:

- Project
- Ownership
- Membership
- Scope

---

# 31. Sensitive Data

ข้อมูล Sensitive ต้องมี Access Control เพิ่ม

ตัวอย่าง:

- Identity
- KYC
- Payment
- Bank Information
- Security
- Audit

---

# 32. Identity Verification Level

Kao ID สามารถมี Verification Level

ตัวอย่าง:

Level 0:

Unverified

Level 1:

Basic Verified

Level 2:

Identity Verified

Level 3:

Enhanced Verification

การเข้าถึงบริการบางประเภท
สามารถกำหนด Minimum Verification Level

---

# 33. Unverified User

User ที่ยังไม่ยืนยันตัวตน
สามารถมีข้อจำกัดตาม Business Rules

ตัวอย่าง:

- จำกัดประเภทสินค้า
- จำกัดมูลค่าธุรกรรม
- จำกัดบริการ
- จำกัด Feature

รายละเอียดจริงต้องอยู่ใน:

docs/business_rules/

---

# 34. Verified User

เมื่อผ่าน Verification
Kao ID สามารถเพิ่ม Identity Status

Kao Brain สามารถใช้ Status นี้
ประกอบ Authorization

แต่ไม่ควรสร้าง Verification Result ซ้ำ
หาก Kao ID เป็น Source of Truth

---

# 35. Identity Reference

Kao Brain ควรเก็บ Reference เช่น:

kao_user_id

แต่ไม่ควร Copy Identity Data
เกินความจำเป็น

หลักการ:

Reference
ไม่ใช่ Duplicate

---

# 36. Token Security

Token ต้อง:

- มี Expiration
- ตรวจ Signature
- ตรวจ Audience
- ตรวจ Issuer
- สามารถ Revoke ตาม Policy

Token ไม่ควรอยู่ใน:

- Git
- Markdown
- Logs
- Database แบบ Plaintext
หากไม่จำเป็น

---

# 37. Service-to-Service

เมื่อ Kao Brain ติดต่อ Service อื่น:

Kao Brain

↓

Service Authentication

↓

Service Authorization

↓

External Service

แต่ละ Service ต้องมี Identity ของตัวเอง

---

# 38. External Provider

ตัวอย่าง:

KYC Provider

Payment Provider

Notification Provider

Kao Brain ไม่ควรส่ง User Credential
ไปยัง Provider

ใช้ Provider Credential
ตาม Integration Policy

---

# 39. Authorization Cache

Authorization Result
สามารถ Cache ได้เมื่อเหมาะสม

แต่ Cache ต้อง:

- มี Expiration
- Invalidate ได้
- ไม่ bypass Security Policy

---

# 40. Audit

ทุก Security-sensitive Action
ต้อง Audit

ต้องรู้:

- User
- Agent
- Action
- Resource
- Scope
- Result
- Time
- Request ID

---

# 41. Security Events

ตัวอย่าง:

- Login
- Logout
- Session Revoked
- Permission Changed
- Role Changed
- Agent Authorized
- Proposal Approved
- Execution Started
- Sensitive Resource Access

---

# 42. Account Status

Kao ID Account Status:

- active
- suspended
- disabled
- deleted

Kao Brain ต้องไม่อนุญาต
การเข้าถึงตาม Policy
หาก Account ถูก Disabled

---

# 43. Authorization Evaluation

ตัวอย่าง:

Request:

Agent KAI-DEV-001
ต้องการแก้ Identity Code

ตรวจ:

1. Agent Active?
2. Task Active?
3. Permission WRITE?
4. Scope = identity?
5. Environment = development?
6. Proposal Approved?
7. Approval ยังไม่หมดอายุ?

ถ้าครบ:

ALLOW

ถ้าไม่ครบ:

DENY

---

# 44. High Risk Evaluation

ตัวอย่าง:

Agent ต้องการแก้ Production Database

ตรวจ:

Agent Permission

+

Task Scope

+

Production Permission

+

Approved Proposal

+

Explicit Approval

+

Environment Policy

หากไม่ครบ:

DENY

---

# 45. Authorization Failure

เมื่อ DENY

API ต้องส่ง Error ที่เหมาะสม

ตัวอย่าง:

FORBIDDEN

SCOPE_DENIED

APPROVAL_REQUIRED

IDENTITY_REQUIRED

VERIFICATION_REQUIRED

---

# 46. No Privilege Escalation

User หรือ Agent ห้าม:

- เพิ่ม Permission ตัวเอง
- เปลี่ยน Role ตัวเอง
- สร้าง Admin ให้ตัวเอง
- Bypass Authorization
- Bypass Approval

---

# 47. Emergency Access

Emergency Access สามารถออกแบบภายหลัง

แต่ต้องมี:

- Authorized Human
- Limited Scope
- Expiration
- Audit
- Post Review

---

# 48. Integration Boundary

Kao ID:

Identity

Kao Brain:

Authorization + Context

Application:

Business Logic

External Provider:

Service Capability

โครงสร้าง:

Kao ID
↓
Kao Brain
↓
Application
↓
Provider

---

# 49. Core Principle

Authentication:

"คุณคือใคร"

Authorization:

"คุณทำอะไรได้"

Verification:

"คุณผ่านเงื่อนไขอะไร"

Approval:

"ใครอนุญาตให้ทำ"

Scope:

"อนุญาตให้ทำกับอะไร"

Environment:

"อนุญาตให้ทำที่ไหน"

Audit:

"เกิดอะไรขึ้น"

---

# 50. Final Principle

Kao ID เป็น Identity Foundation
ของ Kao Ecosystem

Kao Brain เป็น Authorization
และ Context Layer

Application เป็น Business Logic Layer

External Providers เป็น Capability Layer

แต่ละ Layer ต้องมีหน้าที่ชัดเจน
และไม่ควรสร้างข้อมูลซ้ำกันโดยไม่จำเป็น