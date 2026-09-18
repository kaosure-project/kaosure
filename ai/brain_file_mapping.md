# Kao Brain File Mapping

## Purpose

กำหนดตำแหน่ง Source of Truth ของข้อมูลแต่ละประเภท
ใน Kao Brain Project Knowledge System

AI ต้องตรวจสอบ Mapping นี้ก่อนสร้างหรือแก้ไขข้อมูลสำคัญ

---

# 1. Project

## Source of Truth

Project-level documentation

## Main Reference

docs/index.md

## Purpose

ใช้เป็นจุดเริ่มต้นสำหรับค้นหาโครงสร้างเอกสารของ Project

---

# 2. Vision

## Entity

Vision

## Source of Truth

docs/vision/

## Template

docs/templates/

## Workflow

ai/workflows/memory_update.md

## Rule

Vision ต้องได้รับการยืนยันก่อนถือเป็นทิศทางหลักของ Project

---

# 3. Decision

## Entity

Decision

## Source of Truth

docs/decisions/

## Template

docs/templates/decision_template.md

## Workflow

ai/workflows/memory_update.md

## Rule

Decision ที่มี Status = Approved
เท่านั้นที่ถือเป็น Current Decision

---

# 4. Current Context

## Entity

Context

## Source of Truth

docs/context/current_status.md

## Template

docs/templates/status_template.md

## Workflow

ai/workflows/session_start.md

## Rule

Current Status เป็น Snapshot ล่าสุด

ไม่ใช้แทน Historical Record

---

# 5. Task

## Entity

Task

## Source of Truth

docs/tasks/

## Template

docs/templates/task_template.md

## Workflow

ai/workflows/memory_update.md

## Status

TODO
DOING
BLOCKED
DONE

## Rule

Task ที่ BLOCKED ต้องคงอยู่จนกว่า Dependency
หรือ Blocker จะได้รับการแก้ไข

---

# 6. Business Rule

## Entity

Business Rule

## Source of Truth

docs/business_rules/

## Workflow

ai/workflows/memory_update.md

## Rule

Business Rule ที่มีผลต่อระบบ
ต้องได้รับ Approval ก่อนถือเป็น Active Rule

---

# 7. Architecture

## Entity

Architecture

## Source of Truth

docs/architecture/

## Workflow

ai/workflows/memory_update.md

## Rule

Architecture Change ต้องตรวจสอบ:

- Related Decisions
- Related Features
- Related Source Code
- Impact

ก่อนดำเนินการ

---

# 8. Security

## Entity

Security Rule

## Source of Truth

docs/security/

## Workflow

ai/workflows/memory_update.md

## Rule

Security Change เป็น High Risk Operation

ต้องมี Explicit Approval

---

# 9. API

## Entity

API Specification

## Source of Truth

docs/api/

## Workflow

ai/workflows/memory_update.md

## Rule

API Contract ที่ใช้จริงต้องมี Source of Truth เพียงหนึ่งแห่ง

---

# 10. AI Knowledge

## Entity

Knowledge

## Source of Truth

ai/knowledge/

## Purpose

ข้อมูลสำหรับช่วย AI ทำงาน

ตัวอย่าง:

- Coding Standards
- AI Instructions
- Development Practices
- Technical References

## Rule

AI Knowledge ไม่สามารถ Override:

- Approved Decision
- Active Business Rule
- Security Rule
- Architecture Decision

---

# 11. Idea

## Entity

Idea

## Current Source

Conversation / Future Brain Storage

## Permanent Storage

ยังไม่กำหนด Database จริง

เมื่อ Idea มีคุณค่าและได้รับการยืนยัน
สามารถเปลี่ยนเป็น:

Idea
→ Task

หรือ

Idea
→ Proposal
→ Decision

## Rule

Idea ไม่ใช่ Decision

---

# 12. Proposal

## Entity

Proposal

## Source of Truth

ยังไม่เป็น Permanent Knowledge

Proposal อยู่ใน Current Conversation
จนกว่าจะได้รับ Approval หรือ Rejection

## Lifecycle

Proposal
↓
Approved
↓
Decision

หรือ

Proposal
↓
Rejected

## Rule

Proposal ที่ยังไม่ได้รับ Approval
ห้ามถือเป็น Current Direction

---

# 13. Approval

## Entity

Approval

## Current Source

Conversation

## Future Source

Kao Brain Approval Store

## Purpose

บันทึกว่าใครอนุมัติอะไร
เมื่อใด
และอนุมัติการดำเนินการใด

---

# 14. Event

## Entity

Event

## Current Source

Git History
และ Project Documentation

## Future Source

Kao Brain Event Store

## Rule

Event เป็น Historical Record

ไม่ควรถูกแก้ไขย้อนหลัง

---

# 15. Change

## Entity

Change

## Source

Related Decision
และ Change History

## Future Source

Kao Brain Change Store

## Purpose

เก็บรายละเอียดการเปลี่ยนแปลงสำคัญ

---

# 16. Document Reference

## Entity

Document Reference

## Source of Truth

File System / Git Repository

## Purpose

เชื่อม Brain Entity
กับไฟล์จริงใน Repository

ตัวอย่าง:

Decision

↓

docs/decisions/2026-08-08-kao-id-root-platform.md

---

# 17. Source of Truth Priority

เมื่อข้อมูลหลายแหล่งให้ข้อมูลเกี่ยวกับเรื่องเดียวกัน

AI ต้องตรวจตามลำดับ:

1. Approved Decision
2. Active Business Rule
3. Active Architecture
4. Current Status
5. Active Task
6. Project Documentation
7. AI Knowledge
8. Conversation
9. AI Assumption

---

# 18. Conflict Rule

หากข้อมูลขัดแย้งกัน:

AI ต้อง:

1. หยุดการตัดสินใจเอง
2. แสดงข้อมูลที่ขัดแย้ง
3. ระบุ Source
4. ระบุวันที่
5. วิเคราะห์ผลกระทบ
6. เสนอทางเลือก
7. รอผู้บริหารตัดสินใจ

---

# 19. Duplicate Rule

ก่อนสร้างข้อมูลใหม่:

1. Search Existing Entity
2. ตรวจ Source of Truth
3. ตรวจ Related Entity
4. ตรวจ Duplicate
5. เสนอ Update หากมีข้อมูลเดิม

ห้ามสร้างข้อมูลใหม่เพียงเพราะหาไฟล์ไม่เจอ
โดยยังไม่ได้ตรวจสอบ Source ที่เกี่ยวข้อง

---

# 20. Temporary Information

ข้อมูลที่ยังไม่แน่นอน:

- Conversation
- Draft
- Proposal
- Temporary Implementation

ต้องไม่ถูกถือเป็น Permanent Truth
จนกว่าจะผ่านกระบวนการที่เหมาะสม

---

# 21. File Ownership

ข้อมูลหนึ่งประเภทต้องมีเจ้าของหลัก:

Vision
→ docs/vision/

Decision
→ docs/decisions/

Context
→ docs/context/

Task
→ docs/tasks/

Business Rule
→ docs/business_rules/

Architecture
→ docs/architecture/

Security
→ docs/security/

API
→ docs/api/

AI Knowledge
→ ai/knowledge/

---

# 22. Core Rule

ไฟล์หนึ่งไฟล์สามารถ Reference ข้อมูลจากที่อื่นได้

แต่ไม่ควรสร้าง Source of Truth ซ้ำ

ตัวอย่าง:

Current Status สามารถบอกว่า:

"กำลังทำ Identity"

แต่รายละเอียด Identity ต้องอยู่ที่:

docs/features/
หรือ
docs/architecture/

ไม่ควรคัดลอกรายละเอียดทั้งหมดมาไว้ใน Current Status

---

# 23. Future Database Migration

เมื่อ Kao Brain เปลี่ยนจาก Markdown
ไปเป็น Database:

Database จะกลายเป็น Structured Source of Truth

แต่ File Repository ยังคงใช้สำหรับ:

- Documentation
- Specifications
- Architecture
- Decisions
- Human-readable Knowledge

การเปลี่ยนต้องไม่ทำให้ข้อมูลซ้ำหรือขัดแย้งกัน

---

# 24. Goal

เป้าหมายของ Mapping นี้คือ:

One Entity
→ One Primary Source
→ Many References

ไม่ใช่:

One Entity
→ Many Copies

---

# 25. AI Rule

เมื่อ AI ไม่แน่ใจว่าข้อมูลควรอยู่ที่ไหน

ห้ามเดา

ต้องถามผู้บริหาร
หรือเสนอ Storage Location ก่อนบันทึก