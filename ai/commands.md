# Kao AI Commands

## Purpose

กำหนดคำสั่งมาตรฐานสำหรับ AI ที่ทำงานกับ Kao Ecosystem

คำสั่งสามารถถูกเรียกผ่านภาษาธรรมชาติ
โดย AI ต้องแปลงเจตนาของผู้ใช้ให้เป็น Command
ก่อนดำเนินการ

---

# Core Principle

AI ต้องแยก:

User Intent
→ Command
→ Target
→ Proposed Action
→ Approval
→ Execution

AI ห้ามดำเนินการเปลี่ยนแปลงสำคัญ
เพียงเพราะสามารถตีความคำพูดได้

ต้องเสนอและรอ Approval ตามกฎของ Project

---

# Command: SAVE

## Purpose

บันทึกข้อมูลที่มีคุณค่าต่อ Project

## Example

"บันทึกเรื่องนี้ไว้"

"จำอันนี้ไว้"

"เก็บแนวคิดนี้ไว้"

## Process

1. วิเคราะห์ประเภทข้อมูล
2. เลือก Storage Location
3. สรุปข้อมูลที่จะบันทึก
4. เสนอให้ผู้บริหารตรวจสอบ
5. รอ Approval
6. บันทึก

---

# Command: DECISION

## Purpose

บันทึกการตัดสินใจที่ได้รับการอนุมัติ

## Example

"ตกลงเอาแบบนี้"

"ใช้แนวทางนี้"

"ตัดสินใจแบบนี้"

## Process

1. สรุป Decision
2. ระบุ Reason
3. ระบุ Impact
4. ตรวจสอบ Decision เดิม
5. เสนอ
6. รอ Approval
7. บันทึกใน:

docs/decisions/

## Rule

ห้ามสร้าง Status: Approved
หากยังไม่ได้รับการยืนยัน

---

# Command: TASK

## Purpose

สร้างงานใหม่

## Example

"เพิ่มงานนี้ไว้"

"อันนี้ต้องกลับมาทำ"

"สร้าง Task ไว้"

## Process

1. ตรวจสอบว่ามี Task เดิมหรือไม่
2. ถ้ามี ให้เสนอ Update
3. ถ้าไม่มี ให้สร้าง Proposal
4. รอ Approval
5. สร้าง Task

---

# Command: UPDATE_TASK

## Purpose

เปลี่ยนสถานะของ Task

## Status

TODO
DOING
BLOCKED
DONE

## Example

"ตอนนี้เริ่มทำอันนี้"

→ DOING

"อันนี้ติดไว้ก่อน"

→ BLOCKED

"อันนี้ทำเสร็จแล้ว"

→ DONE

## Rule

AI ห้ามเปลี่ยนเป็น DONE
โดยไม่มีการยืนยันจากผู้บริหาร

---

# Command: CONTINUE

## Purpose

กลับมาทำงานที่ค้างไว้

## Example

"ทำงานที่ค้างต่อ"

"กลับมาทำส่วนนี้"

"ต่อจากเมื่อวาน"

## Process

1. Read Current Status
2. Read DOING
3. Read BLOCKED
4. Read related Tasks
5. Read related Decisions
6. Identify Next Action
7. Propose
8. Wait Approval

---

# Command: STATUS

## Purpose

รายงานสถานะ Project

## Example

"ตอนนี้เราอยู่ตรงไหน"

"งาน Kao ID ถึงไหนแล้ว"

"มีอะไรค้างบ้าง"

## Read

docs/context/current_status.md

docs/tasks/

## Output

- Current Phase
- Current Focus
- Doing
- Blocked
- Todo
- Recent Decisions
- Next Step

---

# Command: SEARCH

## Purpose

ค้นหา Project Knowledge

## Example

"หาเรื่อง Kao ID ที่เราเคยตัดสินใจไว้"

"เราเคยคุยเรื่อง KYC ไว้ยังไง"

## Search Priority

1. Approved Decisions
2. Business Rules
3. Architecture
4. Current Status
5. Tasks
6. Documentation
7. AI Knowledge

---

# Command: PROPOSE

## Purpose

เสนอแนวทางโดยยังไม่ดำเนินการ

## Example

"วิเคราะห์ว่าควรทำยังไง"

"เสนอวิธีแก้ให้หน่อย"

## Output

- Problem
- Analysis
- Options
- Recommendation
- Impact
- Risk
- Required Changes

## Rule

ยังไม่ดำเนินการ

รอ Approval

---

# Command: APPROVE

## Purpose

อนุมัติ Proposal

## Example

"อนุมัติ"

"เอาแบบนี้"

"ตกลง"

"ทำเลย"

## Process

AI ต้องตรวจสอบว่า Proposal ล่าสุดคืออะไร

หากไม่มี Proposal ที่ชัดเจน
AI ต้องถามเพื่อป้องกันการตีความผิด

---

# Command: REJECT

## Purpose

ปฏิเสธ Proposal

## Example

"ไม่เอา"

"ยกเลิกแนวทางนี้"

"ไม่ใช้แบบนี้"

## Process

บันทึกผลการปฏิเสธเมื่อมีความสำคัญ
และไม่ใช้ Proposal นั้นเป็น Current Direction

---

# Command: DEPRECATE

## Purpose

ระบุว่าข้อมูลเดิมไม่ใช้งานแล้ว

## Example

"อันนี้ไม่ใช้แล้ว"

"แนวทางนี้เลิกใช้"

## Rule

ไม่ลบทิ้งทันที

เปลี่ยนสถานะเป็น Deprecated
หรือ Superseded ตามกรณี

---

# Command: BLOCK

## Purpose

ระบุว่างานไม่สามารถดำเนินการต่อได้

## Example

"ค้างไว้ก่อน"

"ยังทำต่อไม่ได้"

"ต้องรอส่วนนี้ก่อน"

## Required Information

- Task
- Blocked Reason
- Dependency
- Expected Condition

---

# Command: COMPLETE

## Purpose

เสนอปิดงาน

## Example

"งานนี้เสร็จแล้ว"

## Rule

AI ต้องตรวจสอบ Completion Criteria

จากนั้นเสนอ:

"พบว่าเงื่อนไขครบแล้ว
ต้องการปิด Task เป็น DONE หรือไม่?"

เมื่อได้รับ Approval
จึงเปลี่ยนเป็น DONE

---

# Command: CHANGE

## Purpose

เสนอการเปลี่ยนแปลงจากแนวทางเดิม

## Process

1. Find Existing Decision
2. Compare New Proposal
3. Analyze Impact
4. Explain Difference
5. Create New Proposal
6. Wait Approval
7. If Approved:
   - Create New Decision
   - Mark Previous Decision as Superseded
   - Update Related Documentation

---

# Command: SUMMARY

## Purpose

สรุปข้อมูลหรือการสนทนา

## Example

"สรุปเรื่องนี้ให้หน่อย"

## Rule

Summary ไม่ได้หมายความว่าต้องบันทึก

หากต้องการบันทึก
ต้องใช้ SAVE หรือ Command ที่เกี่ยวข้อง

---

# Command: CLEANUP

## Purpose

ตรวจสอบข้อมูลซ้ำ
ข้อมูลเก่า
และข้อมูลที่ไม่ใช้งาน

## Process

AI ต้อง:

- หา Duplicate
- หา Deprecated
- หา Superseded
- หา Outdated Context
- เสนอสิ่งที่ควรจัดการ

## Rule

AI ห้ามลบข้อมูลสำคัญเอง

ต้องเสนอและรอ Approval

---

# Command: REVIEW

## Purpose

ตรวจสอบคุณภาพของ Project

## Example

"ตรวจระบบให้หน่อย"

"มีอะไรผิดมาตรฐานไหม"

## Check

- Architecture
- Code Structure
- Documentation
- Tasks
- Decisions
- Security
- Testing
- Consistency

## Output

- Findings
- Severity
- Recommendation
- Impact

---

# Command: SYNC

## Purpose

ตรวจสอบความสอดคล้องระหว่าง Project Knowledge

## Check

Current Status
vs
Tasks
vs
Decisions
vs
Documentation
vs
Source Code

## Example

"เช็กว่าข้อมูลเราตรงกันไหม"

## Output

- Consistent
- Conflict
- Missing Information
- Outdated Information

---

# Command: ASK

## Purpose

ใช้เมื่อข้อมูลไม่เพียงพอ

AI ต้องถามผู้ใช้แทนการเดา

## Rule

ห้ามสร้างข้อมูลขึ้นเอง
เพื่อเติมข้อมูลที่ไม่ทราบ

---

# Command Priority

เมื่อมีหลาย Command ในข้อความเดียว

AI ต้องเรียงลำดับ:

1. ASK
2. SEARCH
3. ANALYZE
4. PROPOSE
5. APPROVE
6. EXECUTE
7. VERIFY
8. UPDATE KNOWLEDGE

---

# Safety Rule

คำสั่งที่เกี่ยวข้องกับ:

- Database
- Security
- Authentication
- Identity
- Payment
- Production
- Data Deletion
- Source Code
- Architecture

ต้องผ่าน Proposal และ Approval
ก่อนดำเนินการ

---

# Final Rule

AI มีหน้าที่:

Understand
→ Analyze
→ Propose
→ Wait
→ Execute
→ Verify
→ Report
→ Update

AI ไม่ใช่ผู้มีอำนาจตัดสินใจ

ผู้บริหารเป็นผู้อนุมัติการเปลี่ยนแปลงสำคัญ