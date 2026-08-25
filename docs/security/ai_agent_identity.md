# Kao AI Agent Identity

## 1. Purpose

กำหนด Identity ของ AI Agent
ที่ทำงานภายใน Kao Ecosystem

AI Agent ต้องมี Identity แยกจาก User
และต้องมี Permission ตามหน้าที่ของ Agent

---

# 2. Core Principle

AI Agent ไม่ใช่ User

AI Agent เป็น Actor ที่ได้รับมอบหมายให้ทำงาน

ความสัมพันธ์:

User
↓
Authorizes
↓
AI Agent
↓
Performs Task
↓
Reports Result

---

# 3. Agent Identity

AI Agent แต่ละตัวควรมี:

- agent_id
- agent_name
- agent_type
- role
- description
- status
- owner
- created_at
- updated_at

---

# 4. Agent ID

Agent ID ต้องไม่ซ้ำกัน

ตัวอย่าง:

KAI-ARCH-001

KAI-DEV-001

KAI-QA-001

KAI-RESEARCH-001

KAI-DOC-001

---

# 5. Agent Types

## Architect Agent

หน้าที่:

- วิเคราะห์ Architecture
- ตรวจ Architecture
- เสนอ Architecture
- วิเคราะห์ Impact

ไม่มีสิทธิ์เปลี่ยน Architecture
โดยไม่มี Approval

---

## Developer Agent

หน้าที่:

- วิเคราะห์ Source Code
- เสนอ Code Change
- เขียน Code เมื่อได้รับ Permission
- Run Test
- ตรวจ Build

---

## QA Agent

หน้าที่:

- วิเคราะห์ Test
- สร้าง Test Proposal
- Run Test
- วิเคราะห์ Error
- รายงาน Quality Issue

---

## Research Agent

หน้าที่:

- Research
- Search External Information
- วิเคราะห์ข้อมูล
- สรุปผล

ไม่มีสิทธิ์เปลี่ยน Source Code

---

## Documentation Agent

หน้าที่:

- ตรวจ Documentation
- เสนอ Documentation Update
- จัดรูปแบบ Documentation
- ตรวจความสอดคล้องของเอกสาร

---

# 6. Default Agent

Kao Brain สามารถมี:

Kao General Agent

ทำหน้าที่:

- รับคำสั่ง
- วิเคราะห์ Intent
- ค้น Context
- เรียก Agent ที่เหมาะสม
- รวมผลลัพธ์
- รายงานผู้บริหาร

General Agent ไม่ควรมีสิทธิ์สูงสุดโดยอัตโนมัติ

---

# 7. Agent Permission

Permission ต้องสอดคล้องกับ:

docs/security/ai_permission_model.md

Agent มีสิทธิ์เฉพาะที่จำเป็นต่อ Role

---

# 8. Agent Scope

Agent ต้องมี Scope

ตัวอย่าง:

Developer Agent

Scope:

Kao ID

ไม่ได้หมายความว่าสามารถแก้:

Payment

หรือ

Production

---

# 9. Task Assignment

Agent ควรทำงานผ่าน Task

ตัวอย่าง:

Task:

TASK-20260808-001

Assigned Agent:

KAI-DEV-001

Scope:

Kao ID / Identity

Permission:

READ
SEARCH
PROPOSE
WRITE

---

# 10. Approval

Agent ต้องมี Approval
ก่อนทำ High Risk Operation

Approval ต้องอ้างอิง:

- agent_id
- task_id
- action
- target
- scope
- approval
- approved_by
- approved_at

---

# 11. Agent Status

Agent Status:

- Active
- Suspended
- Disabled
- Archived

---

# 12. Suspended

เมื่อ Agent:

- ทำงานผิดปกติ
- พบ Security Issue
- ใช้ Permission ผิด
- เกิด Behaviour ที่ไม่คาดคิด

สามารถเปลี่ยนเป็น:

Suspended

และหยุดการทำงาน

---

# 13. Disabled

Agent ที่ถูกยกเลิก

ไม่สามารถทำงานได้

แต่ข้อมูล Historical
ยังต้องสามารถตรวจสอบได้

---

# 14. Agent Authentication

Agent ต้อง Authenticate
ก่อนเข้าถึง Kao Brain

ไม่ควรใช้:

User Password

แทน Agent Identity

---

# 15. Agent Credentials

Agent Credential ต้องแยกจาก User Credential

ตัวอย่าง:

Agent Token

Service Credential

OAuth Credential

หรือระบบ Identity Provider

---

# 16. Credential Principle

Agent Credential ต้อง:

- จำกัด Scope
- มีอายุ
- Rotate ได้
- Revoke ได้
- Audit ได้

---

# 17. Agent Identity vs Kao ID

Kao ID เป็น Identity ของ Human User

AI Agent Identity เป็น Identity ของ Machine Actor

ไม่ควรใช้ Identity ประเภทเดียวกันโดยตรง

ความสัมพันธ์:

Human User
↓
Kao ID
↓
Authorizes Agent
↓
AI Agent Identity
↓
Kao Brain
↓
Task

---

# 18. Authorization

Kao Brain ต้องตรวจ:

1. Agent Identity
2. User Authorization
3. Agent Role
4. Agent Permission
5. Task Scope
6. Target Resource

ก่อน Execute

---

# 19. Multi-Agent

ในอนาคต Agent สามารถทำงานร่วมกัน:

General Agent
↓
Architect Agent
↓
Developer Agent
↓
QA Agent
↓
Documentation Agent

แต่ละ Agent ต้องมี Identity ของตัวเอง

---

# 20. Agent Delegation

Agent หนึ่งสามารถเสนอให้ Agent อื่นทำงานได้

ตัวอย่าง:

Developer Agent
↓
สร้าง Test Task
↓
QA Agent

แต่การ Delegation ต้อง:

- มี Scope
- มี Task
- มี Permission
- ตรวจสอบได้

---

# 21. Agent Cannot Escalate Privilege

Agent ห้าม:

- เพิ่ม Permission ตัวเอง
- สร้าง Credential ให้ตัวเอง
- เปลี่ยน Role ตัวเอง
- ปลดข้อจำกัดตัวเอง

---

# 22. Audit

ทุก Action สำคัญควรบันทึก:

- User
- Agent
- Task
- Action
- Target
- Permission
- Approval
- Timestamp
- Result

---

# 23. Human Override

ผู้บริหารสามารถ:

- Suspend Agent
- Disable Agent
- Revoke Permission
- Revoke Credential
- Cancel Task

ได้

AI ไม่สามารถ Override Human Authority

---

# 24. Agent Creation

การสร้าง Agent ใหม่ต้องกำหนด:

- Purpose
- Role
- Scope
- Permission
- Owner
- Security Policy

---

# 25. Agent Lifecycle

Created
↓
Configured
↓
Authorized
↓
Active
↓
Suspended
↓
Reactivated
↓
Disabled
↓
Archived

---

# 26. Agent Registry

ในอนาคต Kao Brain ควรมี Agent Registry

ตัวอย่าง:

| Agent ID | Role | Scope | Status |
|---|---|---|---|
| KAI-GEN-001 | General | Project | Active |
| KAI-ARCH-001 | Architect | Architecture | Active |
| KAI-DEV-001 | Developer | Kao ID | Active |
| KAI-QA-001 | QA | Testing | Active |
| KAI-RES-001 | Research | Research | Active |
| KAI-DOC-001 | Documentation | Docs | Active |

---

# 27. Model Independence

Agent Identity ไม่ควรผูกกับ AI Model

ตัวอย่าง:

KAI-DEV-001

สามารถเปลี่ยน Model:

GPT
→
Claude
→
Gemini
→
Future Model

โดย Agent Identity ยังคงเดิม

---

# 28. Model vs Agent

Model:

ความสามารถด้าน Intelligence

Agent:

Identity
+
Role
+
Permission
+
Scope
+
Task

ดังนั้น:

Model ≠ Agent

---

# 29. Core Security Rule

ทุก Action สำคัญต้องตอบได้ว่า:

WHO

คือใคร

WHAT

ทำอะไร

WHY

ทำไปเพื่ออะไร

WHERE

ทำกับ Resource ไหน

WHEN

ทำเมื่อใด

AUTHORIZATION

ใครอนุมัติ

---

# 30. Final Principle

Kao Ecosystem ต้องสามารถรู้ได้ว่า:

Human
หรือ
AI Agent

เป็นผู้ดำเนินการแต่ละ Action

และ AI Agent ทุกตัวต้องสามารถ:

Authenticate
Authorize
Audit
Suspend
Revoke

ได้