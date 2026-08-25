# Kao Brain Backend Structure

## 1. Purpose

กำหนดโครงสร้าง Backend ของ Kao Brain
ก่อนเริ่ม Implementation จริง

เป้าหมาย:

- แยก Layer ชัดเจน
- แยก Business Logic
- แยก Authentication
- แยก Authorization
- แยก Database
- แยก External Integration
- รองรับการขยายระบบ

---

# 2. Architecture

Backend ใช้ Layered Architecture

Client
↓
API
↓
Application
↓
Domain
↓
Infrastructure
↓
Database / External Services

---

# 3. API Layer

หน้าที่:

- รับ HTTP Request
- Validate Input
- Authenticate Request
- เรียก Application Service
- Format Response
- Handle HTTP Error

API Layer ไม่ควรมี Business Logic สำคัญ

---

# 4. Authentication Layer

หน้าที่:

- Validate Token
- ตรวจ Issuer
- ตรวจ Audience
- ตรวจ Signature
- ตรวจ Expiration
- สร้าง Identity Context

Authentication ไม่ควรตัดสิน Business Permission โดยตรง

---

# 5. Authorization Layer

หน้าที่:

- ตรวจ Role
- ตรวจ Permission
- ตรวจ Scope
- ตรวจ Resource
- ตรวจ Environment
- ตรวจ Approval

ผลลัพธ์:

ALLOW

หรือ

DENY

---

# 6. Application Layer

หน้าที่:

ประสาน Business Use Case

ตัวอย่าง:

- Create Proposal
- Approve Proposal
- Execute Proposal
- Verify Proposal
- Create Task
- Update Context
- Search Knowledge

Application Layer เป็นตัวควบคุม Workflow

---

# 7. Domain Layer

เก็บ Business Rules หลัก

ตัวอย่าง:

- Proposal State Transition
- Approval Rules
- Task Rules
- Agent Rules
- Permission Rules

Domain Layer ไม่ควรรู้ว่าใช้:

PostgreSQL

หรือ

Supabase

หรือ

External API Provider ใด

---

# 8. Infrastructure Layer

หน้าที่:

เชื่อมต่อระบบภายนอก

ตัวอย่าง:

- PostgreSQL
- Redis
- File Storage
- Kao ID
- GitHub
- KYC Provider
- Payment Provider
- AI Provider

---

# 9. Database Layer

หน้าที่:

- Query
- Insert
- Update
- Transaction
- Migration
- Repository

Database Layer ไม่ควรมี Business Workflow

---

# 10. Repository Pattern

Application / Domain
ไม่ควรเรียก SQL โดยตรง

ตัวอย่าง:

ProposalService

↓

ProposalRepository

↓

PostgreSQL

---

# 11. External Provider Interface

External Service
ต้องผ่าน Interface

ตัวอย่าง:

KYCService

↓

KYCProvider

├── Provider A
├── Provider B
└── Provider C

Business Logic
ไม่ควรผูกกับ Provider รายใดรายหนึ่ง

---

# 12. Kao ID Integration

โครงสร้าง:

KaoBrain

↓

IdentityProvider Interface

↓

Kao ID

Kao Brain ไม่ควรฝัง Kao ID Implementation
ไว้ทั่วระบบ

---

# 13. AI Provider Integration

โครงสร้าง:

AIService

↓

AIProvider Interface

├── Provider A
├── Provider B
└── Provider C

สามารถเปลี่ยน AI Model
โดยไม่เปลี่ยน Business Logic

---

# 14. Agent Runtime

Agent Runtime
รับผิดชอบ:

- Agent Identity
- Task Assignment
- Permission
- Tool Access
- Execution
- Result
- Audit

Agent Runtime ต้องไม่สามารถ
ข้าม Authorization Layer

---

# 15. Proposal Workflow

Application Flow:

Create Proposal

↓

Submit Proposal

↓

Approval

↓

Authorization

↓

Execution

↓

Verification

↓

Knowledge Update

---

# 16. Request Context

ทุก Request สำคัญควรสร้าง:

RequestContext

ประกอบด้วย:

- request_id
- trace_id
- actor_type
- actor_id
- user_id
- agent_id
- project_id
- permissions
- scope
- environment

---

# 17. Error Handling

Backend ใช้ Error Model กลาง

ตัวอย่าง:

ValidationError

AuthenticationError

AuthorizationError

NotFoundError

ConflictError

ApprovalRequiredError

ExecutionError

InternalError

---

# 18. Logging

ใช้ Structured Logging

Log ควรมี:

- timestamp
- level
- request_id
- trace_id
- actor_id
- action
- result

ห้าม Log:

- Password
- Token
- API Secret
- Private Key
- Sensitive Identity Data

---

# 19. Audit

Sensitive Action
ต้องสร้าง Audit Event

ตัวอย่าง:

- Login
- Permission Change
- Role Change
- Proposal Approval
- Execution
- Agent Change
- Security Change

---

# 20. Transaction Boundary

Business Operation ที่ต้อง Atomic
ต้องอยู่ใน Transaction Boundary

ตัวอย่าง:

Approve Proposal

ต้อง:

Update Proposal State

+

Create Approval Record

อย่างสอดคล้องกัน

---

# 21. State Machine

State Transition
ต้องถูกตรวจโดย Domain Layer

ตัวอย่าง:

PROPOSED
→
APPROVED

อนุญาต

PROPOSED
→
COMPLETED

ไม่อนุญาต

---

# 22. Security Boundary

API

↓

Authentication

↓

Authorization

↓

Application

↓

Domain

↓

Infrastructure

ไม่มี Layer ใด
สามารถข้าม Security Policy
โดยพลการ

---

# 23. Configuration

Configuration แยกจาก Source Code

ตัวอย่าง:

Environment Variables

- DATABASE_URL
- KAO_ID_ISSUER
- KAO_ID_AUDIENCE
- KAO_ID_JWKS_URL
- AI_PROVIDER
- LOG_LEVEL

Secret ต้องใช้ Secret Manager
หรือ Secure Environment Variable

---

# 24. Environment

Development

Staging

Production

แต่ละ Environment ต้องมี:

- Configuration
- Database
- Credentials
- External Provider
- Logging Policy

แยกจากกัน

---

# 25. Directory Direction

โครงสร้าง Backend เบื้องต้น:

backend/
├── api/
├── application/
├── domain/
├── infrastructure/
├── auth/
├── authorization/
├── agents/
├── proposals/
├── tasks/
├── knowledge/
├── integrations/
├── database/
├── audit/
├── config/
└── tests/

ชื่อ Directory จริงสามารถปรับ
ตาม Framework ที่เลือก

---

# 26. API Modules

ควรรองรับ:

- projects
- contexts
- tasks
- decisions
- knowledge
- proposals
- approvals
- agents
- permissions
- audit
- search

---

# 27. Service Modules

ตัวอย่าง:

ProjectService

TaskService

DecisionService

KnowledgeService

ProposalService

ApprovalService

AgentService

AuthorizationService

AuditService

SearchService

---

# 28. Dependency Direction

ควรเป็น:

API
↓
Application
↓
Domain

และ:

Application
↓
Interfaces
↓
Infrastructure

Domain ไม่ควร Dependency
กับ Infrastructure โดยตรง

---

# 29. Testing Layers

## Unit Test

Domain Rules

---

## Integration Test

Database

Kao ID

External Providers

---

## API Test

HTTP Contract

---

## End-to-End Test

Full Workflow

ตัวอย่าง:

Login

↓

Create Proposal

↓

Approve

↓

Execute

↓

Verify

---

# 30. Health Check

Backend ต้องมี:

GET /health

ตรวจ:

- Application
- Database
- Critical Dependencies

ไม่ควรเปิดเผย Secret
หรือข้อมูลภายใน

---

# 31. Readiness

ควรมี:

GET /ready

ใช้ตรวจว่า Service
พร้อมรับ Traffic หรือไม่

---

# 32. Observability

รองรับ:

- Logs
- Metrics
- Traces
- Health
- Error Tracking

---

# 33. Rate Limiting

Rate Limit
ควรอยู่ที่ API Boundary

พิจารณา:

- User
- Agent
- IP
- Client
- Endpoint

---

# 34. Idempotency

Operation สำคัญ เช่น:

Approve

Execute

Payment

ควรรองรับ:

Idempotency-Key

เพื่อป้องกัน Request ซ้ำ

---

# 35. Queue

งานที่ใช้เวลานาน
ไม่ควร Block HTTP Request

ตัวอย่าง:

- AI Execution
- Document Processing
- Search Indexing
- External API Processing

สามารถใช้:

Queue

Worker

Job System

ใน Phase ต่อไป

---

# 36. Cache

Cache สามารถใช้สำหรับ:

- Read-heavy Data
- Identity Metadata
- Permission Metadata
- Search Result

แต่ Cache ห้ามกลายเป็น
Source of Truth สำหรับ Security

---

# 37. External Integration

ทุก External Provider
ต้องมี:

- Interface
- Adapter
- Credential
- Timeout
- Retry Policy
- Error Handling
- Audit

---

# 38. Timeout

External API
ต้องมี Timeout

ห้ามรอแบบไม่จำกัดเวลา

---

# 39. Retry

Retry ใช้เฉพาะ Error
ที่เหมาะสม

ห้าม Retry Operation
ที่อาจสร้าง Transaction ซ้ำ
โดยไม่มี Idempotency

---

# 40. Circuit Breaker

Provider ที่ล้มเหลวบ่อย
ควรสามารถใช้:

Circuit Breaker

เพื่อป้องกัน Failure Cascade

---

# 41. Security Principle

Backend ต้องใช้:

Least Privilege

Deny by Default

Defense in Depth

Secure by Design

---

# 42. Production Restriction

Development Agent
ไม่ควรมี Production Credential

Production Operation
ต้องผ่าน Environment Policy

และ High Risk Approval

---

# 43. Deployment

Deployment ต้องแยก:

Development

↓

Staging

↓

Production

Production Deployment
ต้องผ่าน Approval ตาม Policy

---

# 44. Migration

Database Migration
ต้องแยกจาก Application Code

Migration ต้อง:

- Versioned
- Reviewed
- Tested
- Audited

---

# 45. API Versioning

Current:

/api/v1

Breaking Change:

/api/v2

---

# 46. Documentation

API ต้องมี:

- Contract
- Request Schema
- Response Schema
- Error Schema
- Authentication
- Authorization
- Examples

---

# 47. OpenAPI

ใน Implementation Phase
ควรสร้าง:

OpenAPI Specification

เพื่อให้:

- Frontend
- Mobile
- Marketplace
- External Developer

สามารถ Integration ได้

---

# 48. Marketplace Integration

ในอนาคต:

Marketplace

↓

Kao ID

↓

Kao Brain / API

↓

Marketplace Backend

Kao ID เป็น Identity Layer

Marketplace เป็น Business Layer

---

# 49. External Application Integration

Application ภายนอกสามารถใช้:

Kao ID Authentication

และ API Scope
ตามที่ได้รับอนุญาต

ไม่ควรได้รับ Database Access โดยตรง

---

# 50. Core Architecture

Kao ID

↓

Identity

↓

Kao Brain API

↓

Authentication

↓

Authorization

↓

Application Services

↓

Domain Rules

↓

Infrastructure

↓

Database / External Providers

---

# 51. Core Principle

API เป็น Contract

Application เป็น Use Case

Domain เป็น Rule

Infrastructure เป็น Integration

Database เป็น Storage

Kao ID เป็น Identity

Kao Brain เป็น Coordination + Context + Authorization Layer

แต่ละส่วนต้องมีหน้าที่ชัดเจน
และสามารถเปลี่ยน Implementation
โดยไม่ต้องรื้อทั้งระบบ