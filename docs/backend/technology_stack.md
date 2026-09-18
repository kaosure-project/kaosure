# Kao Brain Technology Stack

## 1. Purpose

กำหนด Technology Stack สำหรับ Kao Brain Backend

เป้าหมาย:

- พัฒนาได้เร็ว
- ดูแลระยะยาวได้
- รองรับ API
- รองรับ Authentication
- รองรับ PostgreSQL
- รองรับ AI Agent
- รองรับ External API
- รองรับ Marketplace Integration
- รองรับการขยายระบบ

---

# 2. Backend Language

Initial Recommendation:

TypeScript

เหตุผล:

- Type Safety
- เหมาะกับ API Development
- Ecosystem ขนาดใหญ่
- รองรับ Async / Await
- เหมาะกับ External API
- เหมาะกับ AI Integration
- ใช้ร่วมกับ Frontend JavaScript Ecosystem ได้

---

# 3. Runtime

Initial Recommendation:

Node.js

Backend Runtime:

Node.js

Language:

TypeScript

---

# 4. API Framework

Initial Recommendation:

Fastify

เหตุผล:

- Performance ดี
- TypeScript Support
- Plugin Architecture
- Schema Validation
- เหมาะกับ API Service
- Lightweight

Framework ต้องถูกใช้เป็น API Layer
ไม่ใช่เป็นที่เก็บ Business Logic ทั้งหมด

---

# 5. API Specification

มาตรฐาน:

OpenAPI

เป้าหมาย:

- API Documentation
- Contract Validation
- Client Generation
- External Integration

---

# 6. Validation

Initial Recommendation:

Zod

ใช้สำหรับ:

- Request Validation
- Response Validation
- Environment Validation
- Internal Data Validation

Validation ต้องเกิดก่อน
Business Logic

---

# 7. Database

Initial Recommendation:

PostgreSQL

เหตุผล:

- Relational Database
- ACID Transaction
- Foreign Key
- JSONB
- Full Text Search
- Extension Support
- เหมาะกับ Structured State

---

# 8. Database Provider

ยังไม่ Lock

สามารถเลือก:

- Supabase
- Managed PostgreSQL
- Self-hosted PostgreSQL

Application ต้องไม่ผูกกับ Provider

---

# 9. Database Access

Initial Direction:

Repository Pattern

Application:

Service

↓

Repository

↓

PostgreSQL

ORM / Query Tool
สามารถเลือกภายหลัง

ตัวเลือก:

- Prisma
- Drizzle
- Kysely
- node-postgres

ต้องเลือกหนึ่งตัวก่อนเริ่ม Migration จริง

---

# 10. Migration

Database Migration
ต้องเป็น Version Controlled

ตัวเลือก:

- Prisma Migrate
- Drizzle Kit
- Flyway
- Liquibase
- Supabase Migration

Tool ต้องเลือกให้สอดคล้อง
กับ Database Access Layer

---

# 11. Authentication

Kao ID

Kao ID เป็น Identity Provider

Backend:

Resource Server

ต้องตรวจ:

- Signature
- Issuer
- Audience
- Expiration
- Subject

---

# 12. Authorization

Authorization อยู่ใน Kao Brain

ต้องตรวจ:

- Project Membership
- Role
- Permission
- Scope
- Environment
- Approval

Default:

DENY

---

# 13. Token Standard

Initial Direction:

OAuth 2.0

และ

OpenID Connect

หาก Kao ID ใช้ OIDC

Kao Brain สามารถทำหน้าที่:

Resource Server

---

# 14. AI Integration

AI Provider ต้องผ่าน:

AIProvider Interface

ตัวอย่าง:

AIService

↓

AIProvider

├── Provider A
├── Provider B
└── Provider C

Business Logic
ไม่ควรผูกกับ Model Provider

---

# 15. Agent Runtime

Agent Runtime ใช้:

TypeScript / Node.js

รับผิดชอบ:

- Agent Identity
- Task
- Tool
- Permission
- Execution
- Result
- Audit

Agent Runtime
ห้าม bypass Authorization

---

# 16. External API

External API
ต้องใช้ Adapter Pattern

ตัวอย่าง:

KYCProvider

PaymentProvider

NotificationProvider

MarketplaceProvider

---

# 17. HTTP Client

Initial Recommendation:

Native fetch

หรือ HTTP Client
ที่มี Timeout / Retry / Interceptor

ทุก External Request
ต้องกำหนด:

- Timeout
- Error Handling
- Retry Policy

---

# 18. Queue

ยังไม่จำเป็นใน Phase แรก

เมื่อมี Long-running Task
สามารถเพิ่ม:

Redis

และ

Queue Worker

หรือ Managed Queue

---

# 19. Cache

ยังไม่จำเป็นใน Phase แรก

สามารถเพิ่ม Redis
เมื่อมี:

- High Read Load
- Permission Cache
- Search Cache
- Session Metadata

Cache ไม่ใช่ Source of Truth

---

# 20. Search

Phase 1:

PostgreSQL Full Text Search

Phase 2:

Hybrid Search

Keyword

+

Semantic

Phase 3:

Vector Search

สามารถใช้:

pgvector

---

# 21. Logging

Structured Logging

Initial Direction:

Pino

Log Format:

JSON

ทุก Request สำคัญควรมี:

- request_id
- trace_id
- actor_id
- action
- result

---

# 22. Testing

Unit Test:

Vitest

Integration Test:

Vitest

API Test:

Fastify Inject / HTTP Test

End-to-End:

Playwright หรือ API E2E Framework
ตามความเหมาะสม

---

# 23. Code Quality

ควรใช้:

ESLint

Prettier

TypeScript Strict Mode

---

# 24. TypeScript

ต้องเปิด:

strict: true

เป้าหมาย:

ลด Runtime Error
และเพิ่ม Type Safety

---

# 25. Package Management

Initial Recommendation:

pnpm

เหตุผล:

- Fast
- Disk Efficient
- Workspace Support
- เหมาะกับ Monorepo

---

# 26. Repository Structure

Initial Direction:

kao/
├── apps/
│   └── brain-api/
│
├── packages/
│   ├── contracts/
│   ├── domain/
│   ├── auth/
│   └── integrations/
│
├── docs/
│
└── package.json

โครงสร้างจริงสามารถปรับได้
เมื่อเริ่ม Implementation

---

# 27. Monorepo Direction

Initial Recommendation:

Monorepo

เหตุผล:

Kao Ecosystem
มีโอกาสมีหลาย Application:

- Kao ID
- Kao Brain
- Kao Marketplace
- Kao Admin
- Kao Developer Tools

สามารถแชร์:

- API Contracts
- Types
- Auth Utilities
- SDK
- Domain Types

---

# 28. Shared Contracts

Shared Package:

packages/contracts

ใช้เก็บ:

- API Schema
- DTO
- Error Codes
- Event Schema
- Identity Claims

ไม่ควรเก็บ Business Logic
ทั้งหมดไว้ใน Shared Package

---

# 29. Domain Package

packages/domain

ใช้เก็บ:

- Entities
- Value Objects
- Business Rules
- State Machines

Domain ไม่ควร Dependency
กับ Fastify หรือ PostgreSQL

---

# 30. Auth Package

packages/auth

ใช้เก็บ:

- Token Validation
- Identity Context
- Authorization Types
- Permission Types

Kao ID Integration
อยู่ที่ Integration Layer

---

# 31. Integration Package

packages/integrations

ใช้สำหรับ:

- Kao ID
- AI Provider
- KYC Provider
- Payment Provider
- GitHub
- Marketplace

แต่ละ Provider
ต้องมี Adapter

---

# 32. Environment Variables

ตัวอย่าง:

NODE_ENV

PORT

DATABASE_URL

KAO_ID_ISSUER

KAO_ID_AUDIENCE

KAO_ID_JWKS_URL

AI_PROVIDER

AI_API_KEY

LOG_LEVEL

ห้าม Commit Secret

---

# 33. Secret Management

Production:

Secret Manager

หรือ

Secure Environment Variables

ห้ามเก็บ Secret ใน:

- Git
- Markdown
- Source Code
- Docker Image

---

# 34. Docker

Backend ควรสามารถ Run ผ่าน Docker

แต่ไม่จำเป็นต้องใช้ Docker
สำหรับ Local Development
หากไม่จำเป็น

---

# 35. CI/CD

ใน Implementation Phase
ควรมี:

- Install
- Type Check
- Lint
- Unit Test
- Integration Test
- Build
- Migration Check

---

# 36. Deployment

Development

↓

Staging

↓

Production

ทุก Environment
ต้องมี Configuration แยก

---

# 37. Health

Endpoint:

GET /health

---

# 38. Readiness

Endpoint:

GET /ready

---

# 39. API Version

Current:

/api/v1

---

# 40. Security

ต้องมี:

- HTTPS Production
- Input Validation
- Authentication
- Authorization
- Rate Limiting
- Audit
- Secret Management
- Security Headers
- Dependency Updates

---

# 41. Dependency Security

ต้องตรวจ:

- Vulnerability
- Outdated Package
- License
- Supply Chain Risk

---

# 42. Performance

เริ่มต้นเน้น:

Correctness

Security

Maintainability

ก่อน Optimize Performance

---

# 43. Scalability

Initial:

Single Backend Service

สามารถแยก Service
เมื่อจำเป็นจริง

ไม่เริ่มด้วย Microservices
โดยไม่มีเหตุผล

---

# 44. Architecture Direction

Initial:

Modular Monolith

เหตุผล:

- พัฒนาเร็ว
- Debug ง่าย
- Deployment ง่าย
- Transaction ง่าย
- เหมาะกับช่วงเริ่มต้น

สามารถแยก Service ภายหลังได้

---

# 45. Core Modules

Backend Modules:

- auth
- authorization
- projects
- contexts
- decisions
- tasks
- knowledge
- proposals
- approvals
- agents
- audit
- search
- integrations

---

# 46. External Provider Independence

Business Logic
ต้องไม่รู้รายละเอียด Provider

ตัวอย่าง:

PaymentService

↓

PaymentProvider

Business Logic:

createPayment()

ไม่ควรรู้ว่า Provider
ใช้ API Endpoint ใด

---

# 47. AI Model Independence

Agent:

KAI-DEV-001

ไม่ผูกกับ:

GPT

หรือ:

Claude

หรือ:

Gemini

Agent Identity
แยกจาก Model

---

# 48. API Client Independence

External Application
ควรพึ่งพา:

API Contract

ไม่ใช่:

Database

---

# 49. Data Access Rule

Frontend:

ห้าม

↓

Database

Frontend:

ต้อง

↓

API

↓

Authorization

↓

Database

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

Domain

↓

Repository

↓

PostgreSQL

และ:

Application

↓

Integration Interface

↓

External Provider

---

# 51. Initial Technology Decision

Backend:

TypeScript

Runtime:

Node.js

Framework:

Fastify

Validation:

Zod

Database:

PostgreSQL

API Contract:

OpenAPI

Package Manager:

pnpm

Architecture:

Modular Monolith

Repository:

Monorepo

---

# 52. Technology Change Rule

Technology สามารถเปลี่ยนได้

แต่ต้องพิจารณา:

- Migration Cost
- Compatibility
- Security
- Performance
- Maintenance
- Team Capability

การเปลี่ยน Technology ที่มีผลต่อ Architecture
ควรผ่าน Decision Record

---

# 53. Final Principle

เลือก Technology
เพื่อสนับสนุน Architecture

ไม่ใช่:

Architecture
ต้องถูกบังคับให้เข้ากับ Technology

Technology เป็นเครื่องมือ

Kao Brain Architecture
เป็นหลักการ