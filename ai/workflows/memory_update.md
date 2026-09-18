# AI Memory Update Workflow

## Purpose

กำหนดขั้นตอนการจัดการและอัปเดต Project Knowledge
หลังจากมีการสนทนา การวิเคราะห์ หรือการตัดสินใจใหม่

AI ต้องแยกให้ออกระหว่าง:

- Conversation
- Idea
- Decision
- Task
- Knowledge
- Current Context
- Deprecated Information

---

# Core Principle

AI ห้ามบันทึกทุกข้อความจาก Conversation

ต้องคัดกรองก่อนว่าข้อมูลนั้นมีคุณค่าต่อ Project หรือไม่

ข้อมูลที่ไม่มีผลต่อ Project
ไม่ควรถูกบันทึกเป็น Permanent Knowledge

---

# Step 1 — Analyze Conversation

AI วิเคราะห์ว่าข้อมูลที่เกิดขึ้นมีประเภทใด

Possible Types:

- Idea
- Decision
- Task
- Knowledge
- Vision
- Business Rule
- Architecture
- Security Rule
- Current Status
- Note
- Deprecated Information

---

# Step 2 — Determine Persistence

AI ต้องพิจารณาว่าข้อมูลควรถูก:

- ไม่บันทึก
- บันทึกชั่วคราว
- บันทึกถาวร
- อัปเดตข้อมูลเดิม
- สร้างข้อมูลใหม่
- ทำเครื่องหมายว่า Deprecated

---

# Step 3 — User Confirmation

สำหรับข้อมูลที่มีผลต่อ Project

AI ต้องสรุปสิ่งที่จะบันทึกก่อน

ตัวอย่าง:

สิ่งที่ต้องการบันทึก:

Type:
Decision

Title:
Kao ID เป็น Root Platform

Location:
docs/decisions/

Summary:
...

จากนั้นถามผู้บริหารว่า:

"ต้องการบันทึกข้อมูลนี้หรือไม่?"

---

# Step 4 — Approval

AI ต้องรอการยืนยัน

คำยืนยันที่สามารถตีความเป็น Approval:

- อนุมัติ
- ตกลง
- เอาแบบนี้
- ใช้แนวทางนี้
- บันทึก
- ยืนยัน

หากผู้บริหารไม่ยืนยัน

AI ห้ามถือว่าข้อมูลนั้นเป็น Approved Decision

---

# Step 5 — Determine Storage Location

AI ต้องบันทึกข้อมูลไปยังตำแหน่งที่ถูกต้อง

## Vision

docs/vision/

ใช้สำหรับ:

- Vision
- Mission
- Long-term Goals
- Project Principles

---

## Decision

docs/decisions/

ใช้สำหรับ:

- Architecture Decisions
- Product Decisions
- Business Decisions
- Development Decisions

---

## Task

docs/tasks/

ใช้สำหรับ:

- TODO
- DOING
- BLOCKED
- DONE

---

## Current Context

docs/context/

ใช้สำหรับ:

- Current Status
- Current Focus
- Current Progress
- Current Blockers
- Current Priority

---

## Architecture

docs/architecture/

ใช้สำหรับ:

- System Architecture
- Module Architecture
- Integration Architecture
- Technical Design

---

## Business Rules

docs/business_rules/

ใช้สำหรับ:

- Business Logic
- Pricing Rules
- User Rules
- Transaction Rules
- Marketplace Rules

---

## Security

docs/security/

ใช้สำหรับ:

- Security Rules
- Authentication Rules
- Authorization Rules
- Access Control
- Threat Model

---

## API

docs/api/

ใช้สำหรับ:

- API Specification
- Integration Rules
- External Providers
- API Contracts

---

## Knowledge

ai/knowledge/

ใช้สำหรับข้อมูลที่เป็น Knowledge
สำหรับช่วย AI ทำงาน

ไม่ใช้เป็น Source of Truth
หากข้อมูลนั้นเป็น Project Decision หรือ Business Rule

---

# Step 6 — Update Existing Information

ถ้าข้อมูลใหม่เป็นการปรับปรุงข้อมูลเดิม

AI ต้องตรวจสอบข้อมูลเดิมก่อน

ห้ามสร้างข้อมูลซ้ำโดยไม่จำเป็น

---

# Step 7 — Deprecated Information

หากข้อมูลเดิมไม่ใช้งานแล้ว

AI ไม่ควรลบทิ้งทันที

ให้เปลี่ยนสถานะเป็น:

Deprecated

หรือ:

Superseded

และระบุว่า:

- ถูกแทนที่โดยอะไร
- เมื่อใด
- เหตุผล

ข้อมูลที่ Deprecated จะไม่ถูกใช้เป็น Current Source of Truth

---

# Step 8 — Task Update

หากการสนทนาพบว่างานยังไม่เสร็จ

AI ต้องตรวจสอบ Task ที่เกี่ยวข้อง

ถ้ามี Task เดิม:

Update Task

ถ้ายังไม่มี:

เสนอสร้าง Task ใหม่

---

# Step 9 — Temporary Implementation

หากมีการสร้าง Temporary Implementation
เพื่อให้ส่วนอื่นของระบบสามารถทำงานต่อได้

AI ต้องเสนอให้สร้าง Task สำหรับการกลับมาแก้ไข

Task ต้องระบุ:

- Temporary Implementation
- Reason
- Related Files
- Required Final State

---

# Step 10 — Update Current Status

หากมีการเปลี่ยนแปลงที่สำคัญ

AI ต้องเสนอการอัปเดต:

docs/context/current_status.md

Current Status ต้องสะท้อนสถานะล่าสุดของ Project

---

# Step 11 — Preserve History

AI ห้ามลบข้อมูลสำคัญเพียงเพราะข้อมูลนั้นไม่ใช่ Current State แล้ว

ข้อมูลสำคัญควรรักษาประวัติไว้

สถานะสามารถเปลี่ยนเป็น:

- Active
- Deprecated
- Superseded
- Archived

---

# Step 12 — Final Summary

หลังจากการบันทึกหรืออัปเดต

AI ต้องแจ้ง:

- บันทึกอะไร
- บันทึกที่ไหน
- สร้าง Task หรือไม่
- อัปเดต Current Status หรือไม่
- มีข้อมูลเดิมที่ถูกแทนที่หรือไม่

---

# Memory Rules

## Rule 1

Conversation ไม่เท่ากับ Memory

## Rule 2

Memory ไม่เท่ากับ Decision

## Rule 3

Decision ต้องได้รับ Approval

## Rule 4

Task ที่ยังไม่เสร็จต้องไม่ถูกลืม

## Rule 5

ข้อมูลที่ไม่ใช้งานแล้วควรถูก Deprecated
แทนการลบทิ้งทันที

## Rule 6

Current Status ต้องเป็น Snapshot ล่าสุด

## Rule 7

Source of Truth ต้องมีแหล่งเดียว

## Rule 8

ห้ามสร้างข้อมูลซ้ำโดยไม่จำเป็น

## Rule 9

AI ต้องถามเมื่อไม่แน่ใจว่าข้อมูลควรจัดเก็บอย่างไร

## Rule 10

ผู้บริหารเป็นผู้มีอำนาจอนุมัติข้อมูลสำคัญ