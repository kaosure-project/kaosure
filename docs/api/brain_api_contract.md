# Kao Brain API Contract

## 1. Purpose

กำหนด API Contract สำหรับ Kao Brain

API เป็น Interface ระหว่าง:

- Kao ID
- AI Interface
- AI Agents
- Kao Brain
- Project Knowledge
- External Systems

เอกสารนี้เป็น API Specification
ยังไม่ใช่ Implementation

---

# 2. API Principles

Kao Brain API ต้อง:

- ใช้ Versioning
- ใช้ Authentication
- ใช้ Authorization
- ตรวจ Permission
- ตรวจ Scope
- รองรับ Audit
- รองรับ Idempotency สำหรับ Operation ที่เหมาะสม
- ไม่เปิดเผย Secret
- ไม่ผูกกับ AI Model ใด Model หนึ่ง

---

# 3. Base URL

Development:

/api/v1

Staging:

/api/v1

Production:

/api/v1

Base URL จริงจะกำหนดภายหลังตาม Environment

---

# 4. API Version

Current Version:

v1

Future:

v2

เมื่อมี Breaking Change
ต้องสร้าง API Version ใหม่

---

# 5. Authentication

Client ต้อง Authenticate ก่อนเรียก API
ยกเว้น Endpoint ที่กำหนดให้ Public โดยเฉพาะ

Authentication สามารถเชื่อมกับ:

Kao ID

หรือ

Authorized Identity Provider

---

# 6. Authorization

หลัง Authentication
ระบบต้องตรวจ:

- User Identity
- Agent Identity
- Role
- Permission
- Resource
- Scope

Authentication:

"คุณคือใคร"

Authorization:

"คุณทำอะไรได้บ้าง"

---

# 7. Actor

Request สามารถมาจาก:

## Human

User ผ่าน Kao ID

หรือ

## AI Agent

Agent ที่มี Agent Identity

ทุก Request ต้องสามารถระบุ Actor ได้

---

# 8. Standard Request Context

Request ที่มีการ Authentication
ควรมี Context:

- actor_id
- actor_type
- agent_id
- request_id
- trace_id
- timestamp

---

# 9. Response Format

Success:

{
  "success": true,
  "data": {},
  "meta": {
    "request_id": "..."
  }
}

Error:

{
  "success": false,
  "error": {
    "code": "...",
    "message": "...",
    "details": {}
  },
  "meta": {
    "request_id": "..."
  }
}

---

# 10. Error Codes

ตัวอย่าง:

AUTH_REQUIRED

AUTH_INVALID

FORBIDDEN

SCOPE_DENIED

RESOURCE_NOT_FOUND

VALIDATION_ERROR

CONFLICT

RATE_LIMITED

INTERNAL_ERROR

APPROVAL_REQUIRED

APPROVAL_INVALID

PROPOSAL_NOT_FOUND

PROPOSAL_EXPIRED

EXECUTION_DENIED

---

# 11. Project API

## GET

/api/v1/projects

ค้นหา Project

---

## GET

/api/v1/projects/{project_id}

ดู Project

---

## POST

/api/v1/projects

สร้าง Project

ต้องมี Permission:

PROJECT_WRITE

---

## PATCH

/api/v1/projects/{project_id}

แก้ Project

ต้องมี Permission:

PROJECT_WRITE

---

# 12. Context API

## GET

/api/v1/projects/{project_id}/context

อ่าน Current Context

---

## PUT

/api/v1/projects/{project_id}/context

อัปเดต Current Context

ต้องมี:

CONTEXT_WRITE

---

# 13. Decision API

## GET

/api/v1/projects/{project_id}/decisions

ค้น Decisions

---

## GET

/api/v1/decisions/{decision_id}

ดู Decision

---

## POST

/api/v1/projects/{project_id}/decisions

สร้าง Decision Proposal

ไม่ถือเป็น Approved Decision
จนกว่าจะผ่าน Approval

---

## PATCH

/api/v1/decisions/{decision_id}

แก้ Decision

ต้องตรวจสถานะและ Permission

---

# 14. Task API

## GET

/api/v1/projects/{project_id}/tasks

ค้น Tasks

---

## GET

/api/v1/tasks/{task_id}

ดู Task

---

## POST

/api/v1/projects/{project_id}/tasks

สร้าง Task

---

## PATCH

/api/v1/tasks/{task_id}

แก้ Task

---

# 15. Knowledge API

## GET

/api/v1/projects/{project_id}/knowledge

ค้น Knowledge

---

## GET

/api/v1/knowledge/{knowledge_id}

ดู Knowledge

---

## POST

/api/v1/projects/{project_id}/knowledge

สร้าง Knowledge

---

# 16. Proposal API

## GET

/api/v1/projects/{project_id}/proposals

ค้น Proposal

---

## GET

/api/v1/proposals/{proposal_id}

ดู Proposal

---

## POST

/api/v1/projects/{project_id}/proposals

สร้าง Proposal

---

## POST

/api/v1/proposals/{proposal_id}/approve

อนุมัติ Proposal

ต้องมี Explicit Approval

---

## POST

/api/v1/proposals/{proposal_id}/reject

ปฏิเสธ Proposal

---

## POST

/api/v1/proposals/{proposal_id}/cancel

ยกเลิก Proposal

---

# 17. Execution API

## POST

/api/v1/proposals/{proposal_id}/execute

เริ่ม Execution

ต้องตรวจ:

- Proposal Status
- Approval
- Permission
- Agent
- Scope
- Environment

---

## GET

/api/v1/proposals/{proposal_id}/execution

ดู Execution Status

---

# 18. Verification API

## POST

/api/v1/proposals/{proposal_id}/verify

บันทึกผล Verification

ผล:

PASS

หรือ

FAIL

---

# 19. Agent API

## GET

/api/v1/agents

ดู Agent Registry

---

## GET

/api/v1/agents/{agent_id}

ดู Agent

---

## POST

/api/v1/agents

สร้าง Agent

ต้องมี Administrative Permission

---

## PATCH

/api/v1/agents/{agent_id}

แก้ Agent

ต้องมี Administrative Permission

---

# 20. Permission API

Permission ไม่ควรถูกแก้
ผ่าน Endpoint ทั่วไป

การเปลี่ยน Permission ต้องใช้
Administrative Authorization

---

# 21. Audit API

## GET

/api/v1/audit

ค้น Audit Records

ต้องมี:

AUDIT_READ

---

## GET

/api/v1/audit/{audit_id}

ดู Audit Record

---

# 22. Search API

## POST

/api/v1/search

ค้น Project Knowledge

Request สามารถประกอบด้วย:

- query
- project_id
- entity_type
- status
- category
- date_from
- date_to
- limit

---

# 23. Context Assembly API

## POST

/api/v1/context/assemble

สร้าง Working Context

Request:

- project_id
- query
- task_id
- entity_ids
- max_results

Response:

- context
- sources
- confidence

---

# 24. Approval API

## GET

/api/v1/approvals

ค้น Approval

---

## GET

/api/v1/approvals/{approval_id}

ดู Approval

---

## POST

/api/v1/approvals

สร้าง Approval Record

ต้องตรวจสอบ:

- Approver Identity
- Target
- Scope
- Permission

---

# 25. Identity Integration

Kao Brain ไม่ควรเก็บ Human Password

Kao Brain รับ Identity Context
จาก Kao ID หรือ Authorized Identity Provider

ตัวอย่าง:

Kao ID

↓

Authentication

↓

Identity Token

↓

Kao Brain

↓

Authorization

---

# 26. Agent Authentication

AI Agent ต้อง Authenticate
ด้วย Agent Credential

ไม่ใช้ User Password

---

# 27. Scope

ทุก Sensitive Request
ต้องตรวจ Scope

ตัวอย่าง:

Scope:

kao_id.identity

ไม่ได้หมายความว่าสามารถเข้าถึง:

payment.transaction

---

# 28. Approval Enforcement

API ต้องไม่เชื่อเพียง Client
ที่ส่ง:

"approved": true

Server ต้องตรวจ Approval จริง

Approval ต้องมี:

- proposal_id
- approved_by
- approved_at
- scope
- action

---

# 29. Idempotency

Operation ที่อาจถูกส่งซ้ำ
ควรรองรับ Idempotency Key

ตัวอย่าง:

POST /proposals/{id}/approve

หรือ

POST /proposals/{id}/execute

เพื่อป้องกันการ Execute ซ้ำโดยไม่ได้ตั้งใจ

---

# 30. Rate Limiting

API ต้องรองรับ Rate Limit

โดยพิจารณา:

- User
- Agent
- IP
- API Key
- Endpoint

---

# 31. Audit

Sensitive API ต้องสร้าง Audit Event

ตัวอย่าง:

Approval

Execution

Permission Change

Agent Change

Database Operation

Security Change

---

# 32. Transaction Integrity

Operation ที่เปลี่ยน State
ต้องทำแบบ Atomic
เมื่อจำเป็น

ตัวอย่าง:

Approve Proposal

ต้องไม่เกิดสถานะ:

APPROVED

แต่ไม่มี Approval Record

---

# 33. State Validation

API ต้องตรวจ State Transition

ตัวอย่าง:

PROPOSED
→
APPROVED

อนุญาต

แต่:

PROPOSED
→
COMPLETED

ไม่อนุญาต

---

# 34. Proposal State

Allowed:

DRAFT
→
PROPOSED
→
APPROVED
→
EXECUTING
→
COMPLETED
→
VERIFIED

Alternative:

PROPOSED
→
REJECTED

PROPOSED
→
CANCELLED

PROPOSED
→
EXPIRED

---

# 35. Security

API ต้อง:

- Validate Input
- Authenticate
- Authorize
- Rate Limit
- Audit Sensitive Actions
- Protect Secrets
- Prevent Injection
- Validate Object Ownership
- Prevent IDOR
- Use HTTPS ใน Production

---

# 36. External API Integration

Kao Brain สามารถเป็น Integration Layer
สำหรับ External Services

ตัวอย่าง:

- KYC
- Payment
- Marketplace
- Notification
- Search
- AI Provider

แต่ External API Credential
ต้องไม่ถูกเปิดเผยผ่าน Client

---

# 37. Provider Abstraction

External Service
ไม่ควรผูก Business Logic
เข้ากับ Provider รายเดียว

ตัวอย่าง:

KYC

Kao Brain
↓
KYC Provider Interface
├── Provider A
├── Provider B
└── Provider C

Provider สามารถเปลี่ยนได้
โดยไม่ต้องเปลี่ยน Business Logic หลัก

---

# 38. API Contract Stability

Client ต้องพึ่งพา Contract
ไม่ใช่ Internal Implementation

ดังนั้นสามารถเปลี่ยน:

Database

Service

AI Model

Provider

ได้โดยไม่จำเป็นต้องเปลี่ยน Client

ตราบใดที่ Contract ยัง Compatible

---

# 39. Observability

API ควรมี:

- Request ID
- Trace ID
- Structured Logs
- Metrics
- Error Tracking

---

# 40. Future Extensions

สามารถเพิ่ม:

- Webhooks
- Event API
- Streaming
- GraphQL
- WebSocket
- Vector Search
- Knowledge Graph

แต่ไม่จำเป็นต้องสร้างใน v1

---

# 41. API Development Order

Phase 1:

Authentication Context

Phase 2:

Project

Context

Task

Decision

Phase 3:

Knowledge

Search

Phase 4:

Proposal

Approval

Execution

Verification

Phase 5:

Agent

Permission

Audit

Phase 6:

External Integrations

---

# 42. Core Principle

Kao Brain API ต้องเป็น:

Stable Interface

ระหว่าง:

Identity
+
AI
+
Agents
+
Knowledge
+
Project Systems
+
External Services

โดยไม่ผูกกับ Implementation ใด Implementation หนึ่ง