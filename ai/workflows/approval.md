# Kao AI Approval Workflow

## 1. Purpose

กำหนดขั้นตอนการอนุมัติ
ก่อน AI หรือ AI Agent ดำเนินการเปลี่ยนแปลง
ที่มีผลต่อ Kao Ecosystem

หลักการ:

Analyze
→ Propose
→ Review
→ Approve
→ Execute
→ Verify
→ Report

---

# 2. Approval Principle

AI มีหน้าที่วิเคราะห์และเสนอ

ผู้บริหารเป็นผู้อนุมัติ

AI ห้ามถือว่าการเสนอ
เท่ากับการอนุมัติ

---

# 3. Proposal

ทุก Action ที่ต้อง Approval
ต้องเริ่มจาก Proposal

Proposal ต้องระบุ:

- proposal_id
- title
- description
- requested_action
- target
- scope
- reason
- impact
- risk
- dependencies
- expected_result
- affected_files
- affected_systems
- agent_id
- task_id
- created_at
- expires_at

---

# 4. Proposal Status

Proposal มีสถานะ:

- DRAFT
- PROPOSED
- APPROVED
- REJECTED
- EXPIRED
- EXECUTING
- COMPLETED
- FAILED
- CANCELLED

---

# 5. DRAFT

AI กำลังจัดเตรียม Proposal

ยังไม่มีการส่งให้ผู้บริหาร

ยังไม่สามารถ Execute

---

# 6. PROPOSED

AI ส่ง Proposal ให้ผู้บริหารพิจารณา

ยังไม่สามารถ Execute

---

# 7. APPROVED

ผู้บริหารอนุมัติ Proposal แล้ว

สามารถ Execute ได้เฉพาะ:

- Action ที่ระบุ
- Target ที่ระบุ
- Scope ที่ระบุ
- Environment ที่ระบุ

ห้ามขยาย Scope เอง

---

# 8. REJECTED

ผู้บริหารปฏิเสธ Proposal

ห้าม Execute

ถ้าต้องการแนวทางใหม่
ต้องสร้าง Proposal ใหม่

---

# 9. EXPIRED

Proposal หมดอายุ

ห้าม Execute

ต้องสร้าง Proposal ใหม่
หากยังต้องการดำเนินการ

---

# 10. EXECUTING

Agent กำลังดำเนินการ
ตาม Approved Proposal

Agent ต้องไม่เปลี่ยน:

- Target
- Scope
- Action

โดยไม่ได้รับ Approval ใหม่

---

# 11. COMPLETED

Execution เสร็จแล้ว

ต้องผ่าน Verification
ก่อนถือว่างานสมบูรณ์

---

# 12. FAILED

Execution ล้มเหลว

AI ต้อง:

- หยุด
- ไม่พยายามเปลี่ยน Scope เอง
- รายงาน Error
- วิเคราะห์สาเหตุ
- เสนอแนวทางแก้ไข

---

# 13. CANCELLED

Proposal หรือ Execution
ถูกยกเลิกโดยผู้มีอำนาจ

ห้ามดำเนินการต่อ

---

# 14. Approval Levels

## Level 1 — Low Risk

ตัวอย่าง:

- Documentation Formatting
- Read-only Analysis
- Non-critical Documentation

สามารถใช้ Approval แบบมาตรฐาน

---

## Level 2 — Project Change

ตัวอย่าง:

- Source Code
- Architecture Documentation
- Task State
- Project Configuration

ต้องมี Approval

---

## Level 3 — Sensitive

ตัวอย่าง:

- Authentication
- Identity
- KYC
- Database
- API Security

ต้องมี Explicit Approval

---

## Level 4 — Critical

ตัวอย่าง:

- Production
- Data Deletion
- Payment
- Security Policy
- Credential
- Access Control

ต้องมี Explicit Approval
และ Verification หลังดำเนินการ

---

# 15. Approval Information

Approval ต้องบันทึก:

- approval_id
- proposal_id
- approved_by
- decision
- comment
- approved_at

---

# 16. Approval Decision

ค่าที่อนุญาต:

APPROVED

หรือ

REJECTED

ไม่มีสถานะคลุมเครือ

---

# 17. Explicit Approval

สำหรับ High Risk Operation
ต้องมีคำยืนยันที่ชัดเจน

ตัวอย่าง:

"อนุมัติ"

"ยืนยัน"

"ดำเนินการตามข้อเสนอนี้"

หากข้อความกำกวม
AI ต้องถามอีกครั้ง

---

# 18. Scope Lock

เมื่อ Proposal ได้รับ Approval

Scope ต้องถูก Lock

ตัวอย่าง:

Proposal:

แก้ Identity Profile

Scope:

lib/features/identity/profile/

Agent ห้ามขยายเป็น:

lib/features/payment/

โดยไม่มี Approval ใหม่

---

# 19. Change During Execution

หากพบว่าต้องเปลี่ยน Scope:

STOP

→ Analyze

→ Create New Proposal

→ Request Approval

→ Continue

---

# 20. Approval Expiration

Approval สามารถกำหนด Expiration

ตัวอย่าง:

Approval Valid Until:

2026-08-10

หลังจากนั้นต้องขอ Approval ใหม่

---

# 21. Task Relationship

Proposal ควรเชื่อมกับ Task

ตัวอย่าง:

Task:

TASK-20260808-001

Proposal:

PROP-20260808-001

ความสัมพันธ์:

Task
↓
Proposal
↓
Approval
↓
Execution

---

# 22. Agent Relationship

Proposal ต้องระบุ Agent

ตัวอย่าง:

Agent:

KAI-DEV-001

Agent ได้รับสิทธิ์เฉพาะ Scope
ของ Proposal

---

# 23. Human Authority

AI Agent ไม่สามารถ:

- Approve ตัวเอง
- Approve Agent อื่น
- เพิ่ม Permission ตัวเอง
- เปลี่ยน Approval
- ข้าม Approval
- ปลดข้อจำกัดตัวเอง

---

# 24. Approval Separation

ผู้เสนอและผู้อนุมัติ
ควรเป็นคนละ Authority
สำหรับ High Risk Operation

AI ไม่สามารถเป็น Approver
ของตัวเอง

---

# 25. Verification

หลัง Execute

ต้องตรวจสอบ:

- Expected Result
- Tests
- Errors
- Side Effects
- Related Features
- Security
- Data Integrity

---

# 26. Verification Result

ผล Verification:

PASS

หรือ

FAIL

หาก FAIL:

Execution ต้องถูกระบุว่า Failed
และต้องสร้าง Proposal ใหม่สำหรับการแก้ไข

---

# 27. Rollback

สำหรับการเปลี่ยนแปลงที่มีความเสี่ยง
ควรมี Rollback Plan ก่อน Execute

Proposal ต้องระบุ:

Rollback Strategy

หรือ:

Not Applicable

---

# 28. Database Change

Database Change ต้องมี:

- Migration Plan
- Backup Consideration
- Impact Analysis
- Rollback Plan
- Approval
- Verification

---

# 29. Production Change

Production Change ต้องมี:

1. Proposal
2. Impact Analysis
3. Testing
4. Approval
5. Deployment
6. Verification
7. Report
8. Audit

---

# 30. Security Change

Security Change ต้องมี:

- Security Impact
- Threat Consideration
- Scope
- Approval
- Verification

---

# 31. Documentation Update

หลัง Execution

AI ต้องตรวจสอบว่าเอกสารใดได้รับผลกระทบ

ตัวอย่าง:

- Current Status
- Task
- Decision
- Architecture
- Changelog

AI ต้องเสนอการอัปเดต

---

# 32. Audit Trail

ทุก Approval ต้องสามารถตรวจสอบย้อนหลังได้

ต้องรู้:

WHO

อนุมัติโดยใคร

WHAT

อนุมัติอะไร

WHY

เหตุผลอะไร

WHEN

เมื่อใด

SCOPE

ขอบเขตเท่าไร

RESULT

ผลเป็นอย่างไร

---

# 33. Approval Record

ตัวอย่าง:

Proposal ID:

PROP-20260808-001

Action:

Update Identity Repository

Agent:

KAI-DEV-001

Scope:

Kao ID / Identity

Risk:

Medium

Decision:

APPROVED

Approved By:

Founder

Approved At:

2026-08-08

---

# 34. Natural Language Approval

ระบบสามารถแปลงภาษาธรรมชาติเป็น Approval Intent

ตัวอย่าง:

"ตกลง ทำตามนี้"

↓

APPROVE

แต่ต้องตรวจสอบว่า
มี Proposal ล่าสุดที่ชัดเจน

ถ้าไม่มี:

ASK

---

# 35. Ambiguous Approval

ตัวอย่าง:

"โอเค"

ถ้ามี Proposal เดียว
และ Context ชัดเจน:

สามารถตีความเป็น Approval ได้

แต่ถ้ามีหลาย Proposal:

ต้องถามว่า:

"ต้องการอนุมัติ Proposal ไหน?"

---

# 36. No Proposal

ถ้าผู้บริหารพูด:

"ทำเลย"

แต่ยังไม่มี Proposal:

AI ต้องไม่ Execute

ต้องสร้าง Proposal
และขอ Approval

---

# 37. Approval Cannot Expand Scope

Approval สำหรับ:

Identity Profile

ไม่ได้หมายความว่าอนุมัติ:

Authentication

Payment

Database

Production

หรือระบบอื่น

---

# 38. Emergency

ในอนาคตสามารถมี Emergency Procedure

แต่ต้อง:

- มี Policy
- มี Authorized Person
- มี Audit
- มี Post-Review

AI ไม่สามารถประกาศ Emergency
เพื่อข้าม Approval ด้วยตัวเอง

---

# 39. Core Workflow

User Request

↓

Intent Detection

↓

Search Context

↓

Analyze

↓

Create Proposal

↓

PROPOSED

↓

Human Review

↓

APPROVED / REJECTED

↓

If APPROVED

↓

Scope Lock

↓

Agent Execution

↓

Verification

↓

COMPLETED / FAILED

↓

Knowledge Update

↓

Audit

---

# 40. Core Principle

Approval ไม่ใช่แค่ปุ่ม "ตกลง"

Approval คือ:

Authority
+
Action
+
Target
+
Scope
+
Risk
+
Accountability

ดังนั้นทุกการอนุมัติต้องสามารถตรวจสอบย้อนหลังได้