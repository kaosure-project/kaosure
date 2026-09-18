# AI Session Start Workflow

## Purpose

กำหนดขั้นตอนมาตรฐานที่ AI ต้องปฏิบัติ
เมื่อเริ่ม Session ใหม่กับ Kao Ecosystem

AI ต้องใช้ข้อมูลจาก Project Knowledge
แทนการพึ่งพา Chat History เพียงอย่างเดียว

---

# Step 1 — Read Documentation Index

อ่าน:

docs/index.md

Purpose:

ค้นหาว่าเอกสารหลักของ Project อยู่ที่ใด

---

# Step 2 — Read Project Constitution

อ่าน:

docs/vision/project_constitution.md

Purpose:

ทำความเข้าใจกฎ วิสัยทัศน์ และหลักการของ Kao Ecosystem

ห้ามเสนอแนวทางที่ขัดกับหลักการสำคัญ
โดยไม่แจ้งให้ผู้บริหารทราบ

---

# Step 3 — Read Current Status

อ่าน:

docs/context/current_status.md

Purpose:

ตรวจสอบสถานะล่าสุดของ Project

ต้องรู้:

- Current Focus
- Current Phase
- Current Objective
- Current Progress
- In Progress
- Blocked Work
- Current Priority
- Next Step

---

# Step 4 — Read Active Tasks

ตรวจสอบ:

docs/tasks/doing.md

docs/tasks/blocked.md

docs/tasks/todo.md

Purpose:

ค้นหางานที่กำลังทำ
งานที่ติดอยู่
และงานที่ยังต้องทำ

---

# Step 5 — Check Decisions

ตรวจสอบ:

docs/decisions/

Purpose:

ค้นหาการตัดสินใจที่เกี่ยวข้องกับงานปัจจุบัน

AI ต้องถือ Approved Decision
เป็น Source of Truth

หากพบ Decision ที่มีสถานะ:

Rejected

ห้ามนำมาใช้เป็นแนวทางปัจจุบัน

หากพบ:

Superseded

ต้องใช้ Decision ใหม่แทน

---

# Step 6 — Read Relevant Knowledge

อ่านเฉพาะเอกสารที่เกี่ยวข้องกับงานปัจจุบัน

ตัวอย่าง:

Architecture:

docs/architecture/

Database:

docs/database/

Business Rules:

docs/business_rules/

Security:

docs/security/

API:

docs/api/

UI/UX:

docs/ui_ux/

Standards:

docs/standards/

ไม่จำเป็นต้องโหลดเอกสารทั้งหมด
หากไม่เกี่ยวข้องกับงานปัจจุบัน

---

# Step 7 — Check Related Source Code

เมื่อจำเป็นต้องวิเคราะห์หรือแก้ไข Code:

1. ตรวจสอบ Task
2. ตรวจสอบ Decision
3. ตรวจสอบ Architecture
4. ตรวจสอบไฟล์ที่เกี่ยวข้อง
5. วิเคราะห์ผลกระทบ
6. เสนอแนวทาง

AI ห้ามเดาโครงสร้าง Code
หากสามารถตรวจสอบ Source Code จริงได้

---

# Step 8 — Analyze

หลังจากรวบรวม Context แล้ว

AI ต้อง:

- วิเคราะห์สถานะ
- ระบุปัญหา
- ระบุ Dependencies
- ระบุผลกระทบ
- เสนอทางเลือก

---

# Step 9 — Proposal

ก่อนดำเนินการเปลี่ยนแปลงสำคัญ

AI ต้องเสนอ:

- สิ่งที่จะทำ
- เหตุผล
- ไฟล์ที่เกี่ยวข้อง
- ผลกระทบ
- ความเสี่ยง
- ทางเลือก

---

# Step 10 — Wait for Approval

AI ต้องรอการอนุมัติจากผู้บริหาร
ก่อนดำเนินการเปลี่ยนแปลงที่มีผลต่อ:

- Source Code
- Database
- Architecture
- Security
- Business Rules
- Project Decisions
- Production System

---

# Step 11 — Execute

เมื่อได้รับการอนุมัติ

AI จึงดำเนินการตาม Proposal

---

# Step 12 — Verify

หลังดำเนินการ

AI ต้องตรวจสอบ:

- Compile
- Errors
- Tests
- Integration
- Related Features
- Side Effects

ตามความเหมาะสม

---

# Step 13 — Update Project Knowledge

หลังงานเสร็จหรือมีการเปลี่ยนแปลงสำคัญ

AI ต้องเสนอการอัปเดต:

- Current Status
- Tasks
- Decisions
- Changelog
- Related Documentation

AI ต้องรอการอนุมัติก่อนบันทึกข้อมูลสำคัญ
หากข้อมูลนั้นเป็น Decision หรือ Business Rule ใหม่

---

# Step 14 — Final Summary

AI ต้องสรุป:

- สิ่งที่ทำ
- สิ่งที่เปลี่ยน
- ผลการตรวจสอบ
- งานที่ยังค้าง
- งานถัดไป

---

# Core Rule

AI ต้องไม่พึ่งพา Chat History เพียงอย่างเดียว

Project Documentation คือ Source of Truth

Chat History เป็น Context ชั่วคราว

---

# Priority

Source of Truth Priority:

1. Approved Decisions
2. Business Rules
3. Architecture
4. Current Status
5. Active Tasks
6. Relevant Documentation
7. Chat History
8. AI Assumption

หากข้อมูลขัดแย้งกัน

AI ต้องแจ้งความขัดแย้ง
และขอการตัดสินใจจากผู้บริหาร