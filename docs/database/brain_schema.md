# Kao Brain Database Schema

## 1. Purpose

กำหนดโครงสร้างฐานข้อมูลสำหรับ Kao Brain

เอกสารนี้เป็น Database Specification
ยังไม่ใช่ SQL Migration จริง

เป้าหมายคือรองรับ:

- Project
- Context
- Decision
- Task
- Knowledge
- Idea
- Proposal
- Approval
- Agent
- Permission
- Event
- Change
- Document Reference
- Audit

---

# 2. Database Technology

Initial Recommendation:

PostgreSQL

เหตุผล:

- Relational Data
- Transaction Support
- Foreign Key
- JSON Support
- Full Text Search
- Indexing
- Row Level Security
- รองรับการขยายในอนาคต

Database Provider สามารถเป็น:

- Supabase
- Managed PostgreSQL
- Self-hosted PostgreSQL

Database Provider ไม่ควรผูกกับ Business Logic

---

# 3. Naming Convention

Table:

snake_case

Primary Key:

id

Foreign Key:

<entity>_id

Timestamp:

created_at
updated_at

Boolean:

is_<name>

---

# 4. UUID

Primary Key ควรใช้ UUID

ตัวอย่าง:

id UUID PRIMARY KEY

เหตุผล:

- Distributed System
- External API
- Multi-Service
- ลดการเดา ID
- รองรับการย้ายข้อมูล

---

# 5. projects

เก็บข้อมูล Project

Fields:

- id
- name
- slug
- description
- status
- created_at
- updated_at

Status:

- active
- archived

---

# 6. contexts

เก็บ Current Context

Fields:

- id
- project_id
- current_phase
- current_focus
- current_objective
- current_progress
- current_blockers
- current_priority
- next_step
- created_at
- updated_at

Relationship:

projects
1
→
many contexts

แต่ Current Context ที่ Active
ควรมีได้เพียงหนึ่งรายการต่อ Project

---

# 7. decisions

เก็บ Decision

Fields:

- id
- project_id
- title
- decision
- reason
- impact
- status
- approved_by
- approved_at
- supersedes_id
- created_at
- updated_at

Status:

- proposed
- approved
- rejected
- superseded

---

# 8. tasks

เก็บ Task

Fields:

- id
- project_id
- title
- description
- status
- priority
- reason
- current_state
- expected_result
- blocked_reason
- completion_criteria
- created_at
- updated_at
- completed_at

Status:

- todo
- doing
- blocked
- done

---

# 9. task_dependencies

เก็บ Dependency ระหว่าง Task

Fields:

- id
- task_id
- depends_on_task_id
- dependency_type
- created_at

ตัวอย่าง:

Task A

depends_on

Task B

---

# 10. knowledge

เก็บ Structured Knowledge

Fields:

- id
- project_id
- title
- category
- content
- source
- status
- created_at
- updated_at

Status:

- active
- deprecated
- archived

---

# 11. ideas

เก็บ Idea

Fields:

- id
- project_id
- title
- description
- source
- status
- created_at
- updated_at

Status:

- new
- evaluating
- accepted
- rejected
- converted

---

# 12. business_rules

เก็บ Business Rule

Fields:

- id
- project_id
- title
- rule
- reason
- scope
- status
- approved_by
- approved_at
- supersedes_id
- created_at
- updated_at

Status:

- proposed
- active
- deprecated
- superseded

---

# 13. architectures

เก็บ Architecture Information

Fields:

- id
- project_id
- title
- description
- principle
- components
- dependencies
- status
- created_at
- updated_at

Status:

- proposed
- active
- deprecated
- superseded

---

# 14. proposals

เก็บ Proposal

Fields:

- id
- project_id
- task_id
- agent_id
- title
- description
- requested_action
- target
- scope
- reason
- impact
- risk_level
- rollback_plan
- expected_result
- status
- expires_at
- created_at
- updated_at

Status:

- draft
- proposed
- approved
- rejected
- expired
- executing
- completed
- failed
- cancelled

---

# 15. approvals

เก็บ Approval

Fields:

- id
- proposal_id
- approved_by
- decision
- comment
- approved_at
- expires_at
- created_at

Decision:

- approved
- rejected

---

# 16. agents

เก็บ AI Agent

Fields:

- id
- agent_key
- name
- type
- role
- description
- owner
- status
- created_at
- updated_at

Status:

- active
- suspended
- disabled
- archived

---

# 17. agent_permissions

กำหนด Permission ของ Agent

Fields:

- id
- agent_id
- permission
- scope
- environment
- granted_at
- expires_at
- granted_by
- status

Status:

- active
- revoked
- expired

---

# 18. Agent Scope

ตัวอย่าง:

agent:

KAI-DEV-001

permission:

WRITE

scope:

kao_id.identity

environment:

development

Agent ไม่ควรได้รับ Scope:

*

โดย Default

---

# 19. Document References

เชื่อม Database Entity
กับ Markdown / Repository

Fields:

- id
- project_id
- entity_type
- entity_id
- file_path
- section
- description
- created_at
- updated_at

ตัวอย่าง:

entity_type:

decision

entity_id:

UUID

file_path:

docs/decisions/...

---

# 20. Events

เก็บ Historical Events

Fields:

- id
- project_id
- event_type
- actor_type
- actor_id
- target_type
- target_id
- description
- metadata
- created_at

Event เป็น Append-only

ไม่ควร Update หรือ Delete

---

# 21. Changes

เก็บ Change Record

Fields:

- id
- project_id
- target_type
- target_id
- previous_state
- proposed_state
- reason
- impact
- approved_by
- approved_at
- executed_by
- executed_at
- created_at

---

# 22. Audit Logs

เก็บ Security และ Operational Audit

Fields:

- id
- request_id
- actor_type
- actor_id
- agent_id
- action
- target_type
- target_id
- result
- metadata
- ip_address
- user_agent
- created_at

Audit Log ต้องป้องกันการแก้ไขย้อนหลัง

---

# 23. Relationships

projects
│
├── contexts
├── decisions
├── tasks
├── knowledge
├── ideas
├── business_rules
├── architectures
├── proposals
├── agents
├── events
├── changes
└── audit_logs

---

# 24. Proposal Relationship

Project

↓

Task

↓

Proposal

↓

Approval

↓

Execution

↓

Verification

↓

Event

---

# 25. Decision Relationship

Decision สามารถเชื่อมกับ:

- Tasks
- Business Rules
- Architecture
- Proposals
- Documents

ในอนาคตสามารถสร้าง Junction Tables
สำหรับ Many-to-Many Relationship

---

# 26. Task Relationship

Task สามารถเชื่อมกับ:

- Decisions
- Files
- Features
- Dependencies
- Proposals
- Agents

---

# 27. Agent Relationship

Agent

↓

Permissions

↓

Tasks

↓

Proposals

↓

Execution

↓

Audit

---

# 28. Foreign Keys

ควรใช้ Foreign Key
สำหรับข้อมูลที่มีความสัมพันธ์ชัดเจน

ตัวอย่าง:

tasks.project_id

→

projects.id

proposals.task_id

→

tasks.id

approvals.proposal_id

→

proposals.id

---

# 29. Delete Policy

ข้อมูลสำคัญไม่ควรใช้ Hard Delete
โดย Default

ควรใช้:

- Archived
- Deprecated
- Revoked
- Disabled

แทน

---

# 30. Audit Integrity

Audit Logs และ Events
ควรเป็น Append-only

ไม่ควรให้ AI แก้ไขย้อนหลัง

---

# 31. Timestamps

ทุก Entity สำคัญควรมี:

created_at
updated_at

Entity ที่มี Lifecycle
ควรมี:

completed_at
approved_at
executed_at
expired_at

ตามความเหมาะสม

---

# 32. Index Strategy

ควรมี Index สำหรับ:

- project_id
- status
- created_at
- updated_at
- agent_id
- task_id
- proposal_id
- entity_type
- target_id

---

# 33. Search

Phase แรก:

PostgreSQL Full Text Search

Phase ต่อไป:

Hybrid Search

ประกอบด้วย:

Keyword Search
+
Semantic Search

---

# 34. Vector Search

ยังไม่บังคับใน Phase แรก

สามารถเพิ่มภายหลังด้วย:

pgvector

หรือ Vector Database

โดยไม่เปลี่ยน Core Entity

---

# 35. JSON Metadata

Fields ที่มีโครงสร้างยืดหยุ่น
สามารถใช้ JSONB

ตัวอย่าง:

metadata JSONB

แต่ไม่ควรใช้ JSONB
แทน Relational Structure
เมื่อข้อมูลนั้นมีความสัมพันธ์สำคัญ

---

# 36. Multi-Tenant Direction

ในอนาคต Kao Brain
อาจรองรับหลาย Project / Organization

ดังนั้น Entity สำคัญ
ควรมี project_id

และในอนาคตอาจเพิ่ม:

organization_id

---

# 37. Security

Database ต้องรองรับ:

- Authentication
- Authorization
- Row Level Security
- Least Privilege
- Audit

โดยเฉพาะข้อมูล:

- Identity
- Security
- Payment
- KYC
- Credentials

---

# 38. Secrets

ห้ามเก็บ:

- Password
- API Secret
- Private Key
- OAuth Secret
- Database Password

ไว้ใน Brain Database โดยตรง

ควรใช้ Secret Manager

---

# 39. Migration

Database Schema ต้องเปลี่ยนผ่าน Migration

ห้ามแก้ Production Schema
ด้วย Manual Change โดยไม่มี Migration Record

Migration ต้องสามารถ:

- Apply
- Verify
- Rollback เมื่อทำได้

---

# 40. Environment

ควรแยก:

Development
Staging
Production

Database แต่ละ Environment
ไม่ควรใช้ข้อมูลร่วมกันโดยไม่จำเป็น

---

# 41. Backup

Production Database ต้องมี:

- Backup
- Restore Procedure
- Backup Verification

รายละเอียดจริงจะกำหนดใน Production Infrastructure Phase

---

# 42. Source of Truth

Database ไม่ได้แทน Documentation ทั้งหมด

Structured State:

Database

Human-readable Specification:

Git / Markdown

ทั้งสองต้องไม่สร้างข้อมูลขัดแย้งกัน

---

# 43. Initial Architecture

Phase แรก:

Git / Markdown
+
PostgreSQL

Git / Markdown:

- Vision
- Architecture
- Decision
- Documentation
- Specifications

PostgreSQL:

- Structured State
- Tasks
- Proposals
- Approvals
- Agents
- Permissions
- Events
- Audit

---

# 44. Synchronization

หาก Entity มีทั้ง:

Database

และ

Markdown

ต้องกำหนด Primary Source

ไม่ควรให้ทั้งสองฝั่งแก้ข้อมูลเดียวกัน
โดยไม่มี Conflict Resolution

---

# 45. Core Principle

Database มีหน้าที่:

Store Structured State

Git มีหน้าที่:

Store Human-readable Knowledge

Kao Brain API เป็นตัวกลาง:

Human / AI
↓
Kao Brain API
↓
Database + Knowledge Repository

---

# 46. Future Extensions

สามารถเพิ่ม:

- Embeddings
- Vector Search
- Knowledge Graph
- Event Bus
- Cache
- Queue
- Workflow Engine
- Object Storage

โดยไม่เปลี่ยน Core Model
โดยไม่จำเป็น