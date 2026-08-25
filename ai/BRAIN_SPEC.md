# Kao Brain Specification

## 1. Purpose

Kao Brain คือระบบจัดการ Context, Knowledge, Decisions,
Tasks และ Project State สำหรับ Kao Ecosystem

เป้าหมายคือทำให้ AI สามารถทำงานต่อจากบริบทเดิมได้
แม้ผู้ใช้จะเปลี่ยน Chat Session, Device หรือ AI Model

Kao Brain ไม่ใช่ Chat History

Kao Brain คือ Project Knowledge System

---

# 2. Role

Kao Brain ทำหน้าที่เป็น:

- Knowledge Manager
- Context Manager
- Decision Manager
- Task Manager
- Project State Manager
- AI Working Context Provider

Kao Brain ไม่ใช่ผู้ตัดสินใจแทนผู้บริหาร

---

# 3. Human in the Loop

ผู้บริหารเป็นผู้มีอำนาจตัดสินใจขั้นสุดท้าย

AI มีหน้าที่:

Understand
→ Search
→ Analyze
→ Propose
→ Wait for Approval
→ Execute
→ Verify
→ Report
→ Update

AI ห้ามข้ามขั้นตอน Approval
สำหรับการเปลี่ยนแปลงที่มีผลต่อ Project

---

# 4. Source of Truth

Project Knowledge แบ่งตามหน้าที่

## Vision

docs/vision/

ใช้สำหรับ:

- Vision
- Mission
- Long-term Goals
- Project Principles

---

## Decisions

docs/decisions/

ใช้สำหรับ:

- Approved Decisions
- Architecture Decisions
- Business Decisions
- Product Decisions

---

## Tasks

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
- Technical Architecture
- Integration Architecture

---

## Business Rules

docs/business_rules/

ใช้สำหรับ:

- Business Logic
- Product Rules
- Transaction Rules
- Marketplace Rules

---

## Security

docs/security/

ใช้สำหรับ:

- Security Rules
- Authentication
- Authorization
- Access Control

---

## API

docs/api/

ใช้สำหรับ:

- API Specification
- API Contracts
- External Integrations

---

# 5. AI Knowledge

ai/knowledge/

ใช้เก็บ Knowledge ที่ช่วยให้ AI ทำงาน

ตัวอย่าง:

- Coding Standards
- AI Instructions
- Development Practices
- Technical References

AI Knowledge ไม่สามารถ override
Approved Project Decisions หรือ Business Rules

---

# 6. Session Initialization

เมื่อเริ่ม Session ใหม่

AI ต้องปฏิบัติตาม:

ai/workflows/session_start.md

ลำดับหลัก:

1. Read docs/index.md
2. Read Project Constitution
3. Read Current Status
4. Check Active Tasks
5. Check Decisions
6. Read Relevant Documentation
7. Inspect Source Code เมื่อจำเป็น
8. Analyze
9. Propose
10. Wait for Approval

---

# 7. Memory Update

เมื่อมีข้อมูลใหม่

AI ต้องปฏิบัติตาม:

ai/workflows/memory_update.md

AI ต้องจำแนกข้อมูลก่อนบันทึก

ประเภทหลัก:

- Idea
- Decision
- Task
- Knowledge
- Vision
- Business Rule
- Architecture
- Security Rule
- Current Status
- Deprecated Information

---

# 8. Command System

AI Commands ถูกกำหนดไว้ที่:

ai/commands.md

Commands หลัก:

- SAVE
- DECISION
- TASK
- UPDATE_TASK
- CONTINUE
- STATUS
- SEARCH
- PROPOSE
- APPROVE
- REJECT
- DEPRECATE
- BLOCK
- COMPLETE
- CHANGE
- SUMMARY
- CLEANUP
- REVIEW
- SYNC
- ASK

---

# 9. Data Flow

User

↓

AI Interface

↓

Intent Detection

↓

Command

↓

Context Retrieval

↓

Knowledge Retrieval

↓

Decision Retrieval

↓

Task Retrieval

↓

Analysis

↓

Proposal

↓

User Approval

↓

Execution

↓

Verification

↓

Knowledge Update

---

# 10. Context Retrieval

AI ไม่ควรโหลด Project Knowledge ทั้งหมดทุกครั้ง

ต้องเลือกเฉพาะข้อมูลที่เกี่ยวข้องกับงาน

ตัวอย่าง:

หากทำ Kao ID Identity

ควรค้น:

- Identity Architecture
- Identity Business Rules
- Identity Decisions
- Identity Tasks
- Identity Source Code
- Security Rules

ไม่จำเป็นต้องโหลด:

- Marketplace UI
- Agriculture
- unrelated documentation

---

# 11. Conflict Detection

หากพบข้อมูลขัดแย้งกัน

AI ต้อง:

1. ระบุข้อมูลที่ขัดแย้ง
2. ระบุ Source แต่ละตัว
3. ระบุวันที่
4. ระบุผลกระทบ
5. ห้ามเลือกเอง
6. เสนอให้ผู้บริหารตัดสินใจ

---

# 12. Duplicate Detection

ก่อนสร้างข้อมูลใหม่

AI ควรตรวจสอบว่ามีข้อมูลเดิมหรือไม่

ถ้ามี:

- Reuse
- Update
- Supersede

แทนการสร้างข้อมูลซ้ำ

---

# 13. Deprecated Information

ข้อมูลเก่าไม่ควรถูกลบทิ้งทันที

ให้ใช้สถานะ:

Deprecated

หรือ:

Superseded

และระบุ:

- Original Information
- Replacement
- Reason
- Date

---

# 14. Temporary Implementation

Temporary Implementation
สามารถใช้เพื่อให้ Project เดินหน้าต่อได้

แต่ต้องสร้าง Task สำหรับการกลับมาแก้ไข

Task ต้องระบุ:

- Temporary Component
- Reason
- Related Files
- Final Expected State

Temporary Implementation
ห้ามถูกตีความว่า Production Complete

---

# 15. Code Modification

เมื่อ AI ต้องการแก้ Source Code

ต้อง:

1. ตรวจ Current Status
2. ตรวจ Task
3. ตรวจ Decision
4. ตรวจ Architecture
5. ตรวจ Related Files
6. วิเคราะห์ Impact
7. เสนอการเปลี่ยนแปลง
8. รอ Approval
9. แก้ไข
10. Verify
11. Report

---

# 16. High Risk Operations

ต้องมี Approval ก่อนเสมอ:

- Database Modification
- Data Deletion
- Security Configuration
- Authentication
- Identity
- Payment
- Production Deployment
- Architecture Change
- Business Rule Change

---

# 17. Auditability

การเปลี่ยนแปลงสำคัญควรสามารถตรวจสอบย้อนหลังได้

ต้องสามารถระบุ:

- Who
- What
- When
- Why
- Previous State
- New State

---

# 18. Multi-AI Compatibility

Kao Brain ต้องไม่ผูกกับ AI Model ใด Model หนึ่ง

สามารถใช้งานร่วมกับ:

- ChatGPT
- Gemini
- Claude
- Future AI Models
- Internal AI

AI Model เป็น Worker

Kao Brain เป็น Shared Project Knowledge

---

# 19. Multi-Device

Project Knowledge ต้องสามารถใช้งานจาก:

- Mobile
- Web
- Desktop

โดยใช้ Source of Truth เดียวกัน

---

# 20. Future Integration

Kao Brain ในอนาคตสามารถเชื่อมกับ:

- GitHub
- VS Code
- Kao ID
- Supabase
- CI/CD
- Project Management
- AI Agents
- External APIs

การเชื่อมต่อเหล่านี้ต้องผ่านสิทธิ์และ Security Policy
ที่กำหนดไว้อย่างชัดเจน

---

# 21. Security Principle

AI ไม่ควรถือ Credential ที่มีสิทธิ์เกินความจำเป็น

Secrets เช่น:

- Password
- API Key
- Database Credential
- Private Key
- Access Token

ต้องไม่ถูกเก็บใน Project Documentation

---

# 22. Permission Principle

AI ควรได้รับสิทธิ์เท่าที่จำเป็นต่อ Task

หลักการ:

Least Privilege

AI ที่อ่านข้อมูล
ไม่จำเป็นต้องมีสิทธิ์เขียน

AI ที่เขียน Documentation
ไม่จำเป็นต้องมีสิทธิ์ลบ Database

---

# 23. Approval Levels

### Level 1 — Read

อ่านข้อมูลได้

### Level 2 — Propose

วิเคราะห์และเสนอได้

### Level 3 — Write

เขียนข้อมูลที่ได้รับอนุมัติได้

### Level 4 — Execute

ดำเนินการกับระบบได้เมื่อได้รับสิทธิ์

### Level 5 — High Risk

ต้องมี Explicit Approval ทุกครั้ง

---

# 24. Failure Handling

หาก AI ไม่แน่ใจ:

ห้ามเดา

ต้อง:

- แจ้งสิ่งที่ไม่ทราบ
- แสดงข้อมูลที่มี
- ขอข้อมูลเพิ่มเติม
- หรือเสนอทางเลือก

---

# 25. Success Criteria

Kao Brain ถือว่าทำงานได้เมื่อ:

1. AI สามารถค้นหา Project Context ได้
2. AI สามารถค้นหา Decision ได้
3. AI สามารถค้นหา Task ได้
4. AI สามารถระบุงานค้างได้
5. AI สามารถระบุ Temporary Implementation ได้
6. AI สามารถเสนอการเปลี่ยนแปลงได้
7. AI รอ Approval ก่อนเปลี่ยนแปลงสำคัญ
8. AI สามารถอัปเดต Project Knowledge ได้
9. AI สามารถทำงานต่อจาก Session ใหม่ได้
10. AI สามารถทำงานร่วมกับหลาย AI Model ได้

---

# 26. Core Principle

Kao Brain ไม่ใช่ Memory ที่จำทุกอย่าง

Kao Brain คือระบบที่รู้ว่า:

- อะไรสำคัญ
- อะไรเป็นความจริงปัจจุบัน
- อะไรเป็นการตัดสินใจ
- อะไรเป็นงาน
- อะไรยังค้าง
- อะไรถูกยกเลิก
- อะไรถูกแทนที่
- อะไรต้องถามผู้บริหาร

เป้าหมายสูงสุดคือ:

"เปลี่ยน Project Knowledge
ให้กลายเป็น Context ที่ AI สามารถนำไปทำงานต่อได้"