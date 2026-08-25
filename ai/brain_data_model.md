# Kao Brain Data Model

## 1. Purpose

กำหนดโครงสร้างข้อมูลหลักที่ Kao Brain ใช้จัดการ
Project Knowledge และ AI Context

เอกสารนี้เป็น Specification
ยังไม่ใช่ Database Schema จริง

---

# 2. Core Entities

Kao Brain ประกอบด้วยข้อมูลหลัก:

- Project
- Context
- Decision
- Task
- Knowledge
- Idea
- Vision
- Business Rule
- Architecture
- Event
- Approval
- Change
- Document Reference

---

# 3. Project

ใช้ระบุ Project ที่ข้อมูลนั้นเป็นของ

## Fields

- project_id
- project_name
- description
- status
- created_at
- updated_at

## Example

project_id:

KAO-ECOSYSTEM

project_name:

Kao Ecosystem

---

# 4. Context

ใช้เก็บสถานะปัจจุบันของ Project

## Fields

- context_id
- project_id
- current_phase
- current_focus
- current_objective
- current_progress
- current_blockers
- current_priority
- next_step
- updated_at

## Rule

Context เป็น Current Snapshot

ไม่ใช่ Historical Log

---

# 5. Decision

ใช้เก็บการตัดสินใจของผู้บริหาร

## Fields

- decision_id
- project_id
- title
- status
- decision
- reason
- impact
- approved_by
- approved_at
- supersedes
- created_at
- updated_at

## Status

- Proposed
- Approved
- Rejected
- Superseded

## Rule

Decision ที่เป็น Approved
ต้องมี Approval

---

# 6. Task

ใช้จัดการงาน

## Fields

- task_id
- project_id
- title
- status
- priority
- description
- reason
- current_state
- expected_result
- dependencies
- blocked_reason
- related_files
- related_features
- related_decisions
- completion_criteria
- created_at
- updated_at
- completed_at

## Status

- TODO
- DOING
- BLOCKED
- DONE

---

# 7. Knowledge

ใช้เก็บข้อมูลที่ AI ใช้เป็น Reference

## Fields

- knowledge_id
- project_id
- title
- category
- content
- source
- status
- created_at
- updated_at

## Categories

- Technical
- Coding
- Architecture
- Development
- AI
- Reference

## Rule

Knowledge ไม่สามารถ Override
Approved Decision หรือ Business Rule

---

# 8. Idea

ใช้เก็บแนวคิดที่ยังไม่ได้รับการตัดสินใจ

## Fields

- idea_id
- project_id
- title
- description
- source
- status
- related_tasks
- related_decisions
- created_at
- updated_at

## Status

- New
- Evaluating
- Accepted
- Rejected
- Converted

## Important Rule

Idea ไม่เท่ากับ Decision

Idea สามารถถูกเก็บไว้
โดยยังไม่ต้องนำไปใช้จริง

---

# 9. Vision

ใช้เก็บทิศทางระยะยาวของ Project

## Fields

- vision_id
- project_id
- title
- description
- goals
- principles
- status
- created_at
- updated_at

---

# 10. Business Rule

ใช้เก็บกฎทางธุรกิจ

## Fields

- rule_id
- project_id
- title
- rule
- reason
- scope
- status
- approved_by
- approved_at
- created_at
- updated_at

## Status

- Proposed
- Active
- Deprecated
- Superseded

## Rule

Business Rule ที่มีผลต่อระบบ
ต้องได้รับ Approval

---

# 11. Architecture

ใช้เก็บหลักการออกแบบระบบ

## Fields

- architecture_id
- project_id
- title
- description
- principle
- components
- dependencies
- related_decisions
- status
- created_at
- updated_at

---

# 12. Event

ใช้เก็บเหตุการณ์สำคัญของ Project

ตัวอย่าง:

- Decision Approved
- Task Created
- Task Completed
- Architecture Changed
- Knowledge Updated

## Fields

- event_id
- project_id
- event_type
- actor
- target_type
- target_id
- description
- created_at

## Rule

Event เป็น Historical Record

ไม่ควรถูกแก้ไขย้อนหลัง

---

# 13. Approval

ใช้เก็บการอนุมัติ

## Fields

- approval_id
- project_id
- target_type
- target_id
- action
- decision
- approved_by
- approved_at
- comment

## Decision

- Approved
- Rejected

## Rule

Approval ต้องอ้างอิง Target ที่ชัดเจน

---

# 14. Change

ใช้เก็บการเปลี่ยนแปลงสำคัญ

## Fields

- change_id
- project_id
- target_type
- target_id
- previous_state
- proposed_state
- reason
- impact
- approved_by
- approved_at
- executed_at
- created_at

---

# 15. Document Reference

ใช้เชื่อม Entity กับเอกสารจริงใน Repository

## Fields

- reference_id
- entity_type
- entity_id
- file_path
- section
- description

## Example

entity_type:

Decision

entity_id:

DEC-001

file_path:

docs/decisions/2026-08-08-kao-id-root-platform.md

---

# 16. Relationships

## Project

มี:

- Context
- Decisions
- Tasks
- Knowledge
- Ideas
- Vision
- Business Rules
- Architecture
- Events
- Approvals
- Changes

---

## Decision

สามารถเชื่อมกับ:

- Tasks
- Business Rules
- Architecture
- Documents
- Changes

---

## Task

สามารถเชื่อมกับ:

- Decisions
- Files
- Features
- Dependencies
- Changes

---

## Idea

สามารถเชื่อมกับ:

- Tasks
- Decisions

---

# 17. Entity Lifecycle

ข้อมูลทั่วไป:

Created
↓
Active
↓
Updated
↓
Deprecated / Superseded
↓
Archived

---

# 18. Important Distinction

## Conversation

สิ่งที่พูดกัน

ไม่ใช่ Permanent Knowledge

## Idea

แนวคิดที่ยังไม่ได้ตัดสินใจ

## Proposal

ข้อเสนอที่กำลังรอการอนุมัติ

## Decision

สิ่งที่ผู้บริหารตัดสินใจแล้ว

## Task

สิ่งที่ต้องดำเนินการ

## Context

สถานะปัจจุบัน

## Event

ประวัติสิ่งที่เกิดขึ้น

---

# 19. Source of Truth

ประเภทข้อมูลต้องมี Owner ชัดเจน

Vision:

docs/vision/

Decision:

docs/decisions/

Task:

docs/tasks/

Context:

docs/context/

Business Rule:

docs/business_rules/

Architecture:

docs/architecture/

Security:

docs/security/

AI Knowledge:

ai/knowledge/

---

# 20. No Duplicate Source of Truth

ข้อมูลสำคัญหนึ่งเรื่อง
ต้องมี Source of Truth หลักเพียงหนึ่งแห่ง

ข้อมูลที่อื่นสามารถเป็น Reference ได้

แต่ห้ามสร้างข้อมูลที่ขัดแย้งกัน
โดยไม่มีการระบุความสัมพันธ์

---

# 21. AI Retrieval

AI สามารถค้นข้อมูลตาม:

- project
- entity_type
- status
- category
- date
- relationship
- keyword
- file_path

---

# 22. Context Assembly

เมื่อ AI ได้รับ Task

ระบบสามารถประกอบ Context จาก:

Task
+
Current Context
+
Related Decisions
+
Related Business Rules
+
Related Architecture
+
Related Knowledge
+
Related Source Code

เพื่อสร้าง Working Context

---

# 23. Approval Boundary

ข้อมูลที่ต้อง Approval:

- Decision
- Business Rule
- Architecture Change
- Security Change
- Production Change
- Database Change
- Data Deletion
- Task Completion

---

# 24. Future Database

Data Model นี้สามารถนำไปพัฒนาเป็น:

- PostgreSQL
- Supabase
- API
- Search Index
- Vector Search
- Knowledge Graph

ได้ในอนาคต

---

# 25. Core Principle

Kao Brain ต้องไม่เพียงเก็บข้อมูล

แต่ต้องเข้าใจ:

Context
+
Relationship
+
Status
+
History
+
Authority

เพื่อให้ AI สามารถทำงานต่อจากบริบทเดิม
โดยไม่ต้องพึ่ง Chat History เพียงอย่างเดียว