# Kao Brain Retrieval Specification

## 1. Purpose

กำหนดวิธีค้นหา Project Knowledge
เพื่อสร้าง Context ที่เหมาะสมสำหรับ AI

เป้าหมายคือ:

User Query
→ Understand Intent
→ Identify Entities
→ Search Relevant Knowledge
→ Rank Results
→ Build Context
→ Analyze

---

# 2. Core Principle

AI ไม่ควรโหลด Project Knowledge ทั้งหมด

ต้องค้นเฉพาะข้อมูลที่เกี่ยวข้องกับคำถามหรือ Task

---

# 3. Search Sources

ระบบสามารถค้นจาก:

- docs/vision/
- docs/context/
- docs/decisions/
- docs/tasks/
- docs/business_rules/
- docs/architecture/
- docs/security/
- docs/api/
- docs/features/
- docs/database/
- docs/ui_ux/
- ai/knowledge/
- Source Code
- Git History
- Future Brain Database

---

# 4. Search Intent

ก่อนค้นหา AI ต้องจำแนก Intent

## STATUS

ถามสถานะปัจจุบัน

ตัวอย่าง:

"ตอนนี้ Kao ID ถึงไหนแล้ว"

ค้น:

- Current Status
- Doing
- Blocked
- Todo

---

## DECISION

ถามสิ่งที่เคยตัดสินใจ

ตัวอย่าง:

"เราเคยตกลงเรื่อง Kao ID ยังไง"

ค้น:

- Approved Decisions
- Superseded Decisions

---

## TASK

ถามงาน

ตัวอย่าง:

"มีอะไรค้าง"

ค้น:

- DOING
- BLOCKED
- TODO

---

## KNOWLEDGE

ถามความรู้หรือหลักการ

ตัวอย่าง:

"Kao ID ออกแบบยังไง"

ค้น:

- Architecture
- Business Rules
- AI Knowledge
- Related Documentation

---

## HISTORY

ถามสิ่งที่เกิดขึ้นในอดีต

ตัวอย่าง:

"เดือนที่แล้วเราทำอะไรไปบ้าง"

ค้น:

- Changelog
- Git History
- Events
- Decisions
- Tasks

---

## VISION

ถามทิศทาง

ตัวอย่าง:

"เป้าหมาย Kao Ecosystem คืออะไร"

ค้น:

- Vision
- Constitution
- Roadmap

---

## CODE

ถามเกี่ยวกับ Source Code

ตัวอย่าง:

"ระบบ Identity อยู่ตรงไหน"

ค้น:

- Related Tasks
- Architecture
- Features
- Source Code
- Git History

---

# 5. Entity Detection

AI ควรระบุ Entity ที่เกี่ยวข้องกับ Query

ตัวอย่าง:

"Kao ID Identity"

Entities:

Project:
Kao Ecosystem

System:
Kao ID

Feature:
Identity

---

# 6. Keyword Search

ค้นจาก:

- Title
- Description
- Content
- Tags
- File Path
- Related Entity
- Related Feature

---

# 7. Exact Match

หาก Query ระบุชื่อเฉพาะ:

เช่น:

"Kao ID"

ให้ค้น Exact Match ก่อน

---

# 8. Related Search

หลัง Exact Match
ให้ค้น Related Information

ตัวอย่าง:

Kao ID

↓

Identity

↓

KYC

↓

Authentication

↓

Security

↓

Profile

---

# 9. Relationship Search

ระบบควรติดตามความสัมพันธ์:

Decision
→ Task

Decision
→ Architecture

Task
→ File

Task
→ Feature

Business Rule
→ Feature

Architecture
→ Feature

Feature
→ Source Code

---

# 10. Source Priority

ผลการค้นหาต้องเรียงความสำคัญตาม:

1. Approved Decision
2. Active Business Rule
3. Active Architecture
4. Current Status
5. Active Task
6. Relevant Documentation
7. AI Knowledge
8. Historical Information
9. Conversation

---

# 11. Status Priority

ข้อมูล Active มีความสำคัญมากกว่าข้อมูล:

- Deprecated
- Superseded
- Rejected
- Archived

ข้อมูลเหล่านี้สามารถใช้เป็น Historical Context
แต่ต้องไม่ถูกนำเสนอเป็น Current Truth

---

# 12. Recency

เมื่อข้อมูลประเภทเดียวกันมีหลายรายการ
ให้พิจารณา:

- Updated Date
- Created Date
- Status
- Superseded Relationship

ข้อมูลใหม่ไม่ได้แปลว่าถูกต้องกว่าเสมอ

ต้องตรวจ Status และ Authority ด้วย

---

# 13. Conflict Detection

หากผลการค้นพบ:

Decision A:

Approved

Decision B:

Approved

แต่เนื้อหาขัดแย้งกัน

AI ต้อง:

- แจ้ง Conflict
- แสดงทั้งสอง Source
- ไม่เลือกเอง
- เสนอให้ผู้บริหารตัดสินใจ

---

# 14. Context Assembly

หลัง Retrieval

AI ต้องสร้าง Working Context

ตัวอย่าง:

User Query
+
Current Status
+
Relevant Task
+
Related Decision
+
Business Rule
+
Architecture
+
Relevant Source Code

↓

Working Context

---

# 15. Context Limit

ไม่ควรส่งข้อมูลทั้งหมดเข้า AI

ต้อง:

- Rank
- Filter
- Deduplicate
- Summarize เมื่อเหมาะสม

เพื่อให้ Context มีเฉพาะข้อมูลที่จำเป็น

---

# 16. Deduplication

หากข้อมูลเดียวกันปรากฏหลาย Source:

ให้เลือก Source of Truth เป็นหลัก

และเก็บ Reference ของ Source อื่น

---

# 17. Time-Based Search

ระบบควรรองรับ Query เช่น:

- วันนี้
- เมื่อวาน
- สัปดาห์ที่แล้ว
- เดือนที่แล้ว
- ปีที่แล้ว
- ช่วงวันที่กำหนด

---

# 18. Example

User:

"พุดตาน มีอะไรที่เราค้างเกี่ยวกับ Kao ID บ้าง"

System:

Intent:

TASK

Entity:

Kao ID

Search:

docs/tasks/

Filter:

Kao ID

Status:

DOING
BLOCKED
TODO

↓

Return:

Task List

↓

Related Decisions

↓

Related Files

---

# 19. Example

User:

"เราเคยตกลงให้ Kao ID เป็นระบบกลางหรือเปล่า"

Intent:

DECISION

Entity:

Kao ID

Search:

docs/decisions/

↓

Find:

Kao ID Root Platform

Status:

Approved

↓

Return Decision

---

# 20. Example

User:

"ตอนนี้เรากำลังทำอะไร"

Intent:

STATUS

Search:

docs/context/current_status.md

docs/tasks/doing.md

docs/tasks/blocked.md

↓

Return Current Project State

---

# 21. Example

User:

"ทำไมเราเลือกออกแบบ Kao ID แบบนี้"

Intent:

DECISION + KNOWLEDGE

Search:

- Decisions
- Architecture
- Business Rules

↓

Return:

Decision
+
Reason
+
Impact

---

# 22. Code Retrieval

เมื่อ Query เกี่ยวข้องกับ Code:

AI ต้องค้น:

1. Related Task
2. Related Decision
3. Architecture
4. Feature Documentation
5. File Path
6. Source Code
7. Git History

AI ห้ามแก้ Code
จาก Search Result เพียงอย่างเดียว

ต้องตรวจ Source Code จริง

---

# 23. Retrieval Failure

ถ้าค้นไม่พบ:

AI ต้องบอก:

"ไม่พบข้อมูลใน Project Knowledge"

และห้ามสร้างคำตอบขึ้นมาเหมือนเป็นข้อมูลจริง

สามารถเสนอ:

- Search เพิ่ม
- ตรวจ Source Code
- ถามผู้บริหาร

---

# 24. Search Confidence

ผลลัพธ์ควรมีระดับความมั่นใจ:

High

มี Source of Truth โดยตรง

Medium

มีข้อมูลเกี่ยวข้องหลายแหล่ง

Low

พบข้อมูลบางส่วน
แต่ยังไม่มี Source of Truth ที่ชัดเจน

---

# 25. Future Search Technology

ระบบสามารถพัฒนา Retrieval เป็น:

Phase 1:

File Search

Phase 2:

Metadata Search

Phase 3:

PostgreSQL / Supabase Search

Phase 4:

Full Text Search

Phase 5:

Vector Search

Phase 6:

Hybrid Search

Phase 7:

Knowledge Graph

ไม่จำเป็นต้องสร้างทุก Phase ตั้งแต่แรก

---

# 26. Security

Retrieval ต้องเคารพ Permission

AI ไม่ควรค้นข้อมูลที่ User
ไม่มีสิทธิ์เข้าถึง

ข้อมูล Sensitive ต้องมี Access Control

---

# 27. Audit

การค้นข้อมูลที่ Sensitive
ควรสามารถตรวจสอบได้ว่า:

- ใครค้น
- ค้นอะไร
- เมื่อใด
- เพื่ออะไร

---

# 28. Core Principle

Kao Brain ไม่ใช่ระบบที่ "จำทุกอย่าง"

แต่เป็นระบบที่:

Find
→ Rank
→ Validate
→ Relate
→ Assemble
→ Provide Context

เพื่อให้ AI ได้ข้อมูลที่ถูกต้อง
ในเวลาที่ต้องการ
โดยไม่ต้องโหลดทุกอย่างเข้ามา