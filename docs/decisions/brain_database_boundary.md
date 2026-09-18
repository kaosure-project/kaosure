# Decision: Kao Brain Database Boundary

## Status

Accepted

## Date

2026-08-09

---

# 1. Decision

Kao Brain จะใช้ Database Infrastructure
ร่วมกับ Kao Ecosystem ได้

แต่จะไม่สร้างข้อมูลซ้ำ
กับ Identity และ Governance ที่มีอยู่แล้ว
โดยไม่มีเหตุผลที่ชัดเจน

---

# 2. Kao ID / Identity Source of Truth

Kao ID เป็น Source of Truth สำหรับ:

- User Identity
- Authentication
- Profile Reference
- OAuth
- Session
- Identity Documents
- Verification

Existing Tables:

- profiles
- oauth_clients
- oauth_tokens
- sessions
- identity_documents
- verification_requests
- verification_logs

Kao Brain จะอ้างอิง User ด้วย:

kao_user_id / profile_id

ตาม Identity Contract

---

# 3. Existing Governance

ระบบปัจจุบันมี Governance Tables:

- organizations
- permissions
- role_permissions
- approval_policies
- approval_requests
- approval_steps
- approval_histories
- admin_sessions
- audit_logs

ห้ามสร้าง Table ชื่อซ้ำ
โดยไม่ผ่าน Architecture Decision

---

# 4. Governance Boundary

Existing Governance
มีลักษณะ:

Admin / Organization Governance

Kao Brain ต้องการเพิ่ม:

Project Authorization

Agent Authorization

Task Authorization

Execution Authorization

ดังนั้นต้องตรวจสอบก่อนว่า
สามารถ Extend Governance เดิมได้หรือไม่

ห้ามสมมติว่า:

admin_roles

=

project_roles

---

# 5. AI Existing Tables

Existing:

- ai_prompts
- ai_training
- ai_embeddings
- ai_logs

Tables เหล่านี้มีอยู่แล้ว
และเกี่ยวข้องกับ AI Capability

แต่ยังไม่ถือว่าเป็น
Kao Brain Core Data Model

---

# 6. Kao Brain Core Data

Kao Brain ยังต้องมี Domain Data
ที่ไม่มีใน Existing Database

Initial candidates:

- brain_projects
- brain_contexts
- brain_decisions
- brain_tasks
- brain_task_dependencies
- brain_knowledge
- brain_ideas
- brain_business_rules
- brain_architectures
- brain_proposals
- brain_agents
- brain_agent_permissions
- brain_executions

ชื่อจริงสามารถเปลี่ยนได้
หลังจากตรวจ Domain Model อีกครั้ง

---

# 7. Why Brain Prefix

Initial recommendation:

brain_

ใช้เพื่อ:

- ลดชื่อชนกัน
- เห็น Boundary ชัด
- แยก Domain
- ลดความเสี่ยง Migration
- ทำให้ Database สำรวจง่าย

ตัวอย่าง:

brain_projects

brain_tasks

brain_agents

---

# 8. Shared Identity

Brain Tables
ไม่ควรสร้าง Human User Table ใหม่

ใช้ Reference:

profile_id

หรือ:

kao_user_id

ตาม Identity Architecture

---

# 9. Shared Audit

Existing:

audit_logs

สามารถใช้เป็น Audit Infrastructure
ได้หาก Schema รองรับ Brain Requirements

ห้ามสร้าง:

brain_audit_logs

ก่อนตรวจ Existing Audit Capability

---

# 10. Shared Approval

Existing:

approval_policies
approval_requests
approval_steps
approval_histories

สามารถเป็น Foundation
สำหรับ Approval Infrastructure

แต่ต้องตรวจว่า
รองรับ:

- Project
- Agent
- Proposal
- Execution
- Scope
- Environment

หรือไม่

หากไม่รองรับ
ให้ Extend อย่างมี Versioned Migration

ไม่สร้างระบบ Approval ซ้ำ
โดยไม่มี Architecture Decision

---

# 11. Shared Permission

Existing:

permissions
role_permissions

ปัจจุบัน Permission
เชื่อมกับ Admin Role

ดังนั้นยังไม่ถือว่า
รองรับ Project Role โดยอัตโนมัติ

ต้องออกแบบเพิ่มเติมสำหรับ:

- Project Role
- Agent Role
- Resource Scope
- Environment Scope

---

# 12. Brain Authorization

Target:

Human
+
Project
+
Role
+
Permission
+
Scope

Agent
+
Task
+
Permission
+
Scope
+
Approval

---

# 13. Marketplace Boundary

Marketplace เป็น Business Domain

ตัวอย่าง:

- Products
- Shops
- Orders
- Payments
- Shipping
- Reviews

ไม่ควรถูกย้ายเข้า Kao Brain

Kao Brain ทำหน้าที่:

Context

Decision

Task

Agent

Workflow

Authorization

Integration

---

# 14. Identity Boundary

Kao ID:

Who are you?

Kao Brain:

What can you do?

Marketplace:

What are you buying/selling?

---

# 15. Database Strategy

Initial Strategy:

Shared PostgreSQL Infrastructure

+

Logical Domain Boundary

ไม่เริ่มจากการสร้าง Database Server ใหม่

---

# 16. Schema Strategy

Initial recommendation:

public schema

โดยใช้ Table Prefix:

brain_

หากภายหลัง Domain โตมาก
สามารถพิจารณาแยก PostgreSQL Schema:

brain

identity

commerce

แต่ยังไม่จำเป็นใน Phase แรก

---

# 17. Migration Strategy

Brain Migration
ต้องอยู่ใน:

supabase/migrations/

และต้องมี Version

ตัวอย่าง:

20260809xxxx_brain_projects.sql

---

# 18. Migration Safety

ก่อนสร้าง Brain Tables:

- ตรวจ Existing Tables
- ตรวจ Foreign Keys
- ตรวจ RLS
- ตรวจ Permissions
- ตรวจ Naming Conflict
- ตรวจ Migration Order

---

# 19. No Duplicate Identity

ห้ามสร้าง:

brain_users

หากมี:

profiles

เป็น Identity Source of Truth

---

# 20. No Duplicate Approval

ห้ามสร้าง:

brain_approvals

จนกว่าจะตรวจว่า
Existing Approval Infrastructure
ไม่สามารถรองรับ Brain ได้จริง

---

# 21. No Duplicate Permission

ห้ามสร้าง:

brain_permissions

จนกว่าจะตรวจ Existing Permission Model

---

# 22. No Duplicate Audit

ห้ามสร้าง:

brain_audit_logs

จนกว่าจะตรวจ Existing audit_logs

---

# 23. Core Principle

Reuse Existing Infrastructure

แต่ไม่ Reuse แบบฝืน Domain

ถ้า Existing Table
ตรงหน้าที่:

Reuse

ถ้า Existing Table
ใกล้เคียงแต่ไม่พอ:

Extend

ถ้า Existing Table
คนละ Domain:

Create New

---

# 24. Decision Rule

ทุก Table ใหม่ต้องตอบได้ว่า:

1. Existing Table มีหรือไม่?
2. ถ้ามี ใช้ได้หรือไม่?
3. ถ้าใช้ไม่ได้ เพราะอะไร?
4. Extend ได้หรือไม่?
5. ถ้าต้องสร้างใหม่ Boundary คืออะไร?

---

# 25. Final Architecture

Kao ID
↓
Identity

Existing Governance
↓
Admin / Organization Authorization

Kao Brain
↓
Project / Agent / Task / Decision / Context

Marketplace
↓
Commerce

External Providers
↓
Capabilities

---

# 26. Final Principle

Kao Brain ไม่ใช่ Database ใหม่
ที่สร้างทุกอย่างซ้ำจาก Kao ID

Kao Brain คือ Domain Layer
ที่ใช้ Identity และ Infrastructure
ของ Kao Ecosystem

โดยสร้างเฉพาะข้อมูล
ที่เป็น Brain Domain จริง ๆ