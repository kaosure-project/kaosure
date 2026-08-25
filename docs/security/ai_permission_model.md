# Kao AI Permission Model

## 1. Purpose

กำหนดสิทธิ์และข้อจำกัดของ AI
ในการทำงานกับ Kao Ecosystem

เป้าหมายคือ:

ให้ AI สามารถทำงานได้อย่างมีประสิทธิภาพ
โดยใช้สิทธิ์เท่าที่จำเป็น

หลักการ:

Least Privilege
+
Human in the Loop
+
Explicit Approval

---

# 2. Core Principle

AI ไม่ควรมีสิทธิ์มากกว่าที่ Task ต้องใช้

การมีสิทธิ์ Read
ไม่ได้หมายความว่ามีสิทธิ์ Write

การมีสิทธิ์ Write
ไม่ได้หมายความว่ามีสิทธิ์ Delete

การมีสิทธิ์ Execute
ไม่ได้หมายความว่ามีสิทธิ์ Production

---

# 3. Permission Levels

## Level 0 — DENY

ไม่มีสิทธิ์เข้าถึง

---

## Level 1 — READ

สามารถ:

- อ่านไฟล์
- อ่าน Documentation
- อ่าน Project Knowledge
- ค้นหา Repository
- อ่าน Source Code

ไม่สามารถ:

- แก้ไข
- สร้าง
- ลบ

---

## Level 2 — SEARCH

สามารถ:

- Search Knowledge
- Search Tasks
- Search Decisions
- Search Source Code
- Search Git History

ไม่สามารถเปลี่ยนแปลงข้อมูล

---

## Level 3 — PROPOSE

สามารถ:

- วิเคราะห์
- สร้าง Proposal
- วิเคราะห์ Impact
- เสนอ Code Change
- เสนอ Documentation Change
- เสนอ Task
- เสนอ Decision

ไม่สามารถ Execute

---

## Level 4 — WRITE

สามารถเขียนข้อมูล
หลังจากได้รับ Approval

ตัวอย่าง:

- Documentation
- Task
- Decision
- Current Status
- Configuration ที่อนุญาต

---

## Level 5 — CODE EXECUTION

สามารถ:

- แก้ Source Code
- Run Tests
- Run Analyzer
- Build Project

ต้องมี Approval
ก่อนเริ่ม Modification

---

## Level 6 — SYSTEM EXECUTION

สามารถ:

- Run Command
- เปิด Application
- เปิด Project
- เรียก Tool
- ทำ Automation

ต้องผ่าน Security Policy

---

## Level 7 — HIGH RISK

เกี่ยวข้องกับ:

- Database
- Authentication
- Identity
- Payment
- Security
- Production
- Data Deletion
- Secrets

ต้องมี Explicit Approval ทุกครั้ง

---

# 4. Default AI Permission

ค่าเริ่มต้นของ AI:

READ
+
SEARCH
+
PROPOSE

เท่านั้น

AI ไม่มี WRITE หรือ EXECUTE
โดยอัตโนมัติ

---

# 5. Documentation Permission

## Read

Allowed

## Search

Allowed

## Propose

Allowed

## Write

ต้องได้รับ Approval

## Delete

ห้ามโดย Default

---

# 6. Source Code Permission

## Read

Allowed

## Search

Allowed

## Analyze

Allowed

## Propose Change

Allowed

## Modify

ต้องได้รับ Approval

## Delete

ต้องได้รับ Explicit Approval

## Execute

ต้องได้รับ Permission ตาม Task

---

# 7. Git Permission

## Read Repository

Allowed

## Read History

Allowed

## Create Branch

สามารถอนุญาตได้

## Commit

ต้องได้รับ Approval

## Push

ต้องได้รับ Explicit Approval

## Merge

ต้องได้รับ Explicit Approval

## Delete Branch

ต้องได้รับ Explicit Approval

---

# 8. Database Permission

## Read Schema

Allowed

## Read Data

ต้องตรวจ Permission

## Query

ต้องจำกัด Scope

## Insert

ต้องได้รับ Approval

## Update

ต้องได้รับ Approval

## Delete

Explicit Approval เท่านั้น

## Schema Change

Explicit Approval เท่านั้น

---

# 9. Production Permission

AI ไม่มีสิทธิ์ Production
เป็น Default

การ Deploy Production ต้อง:

1. Proposal
2. Impact Analysis
3. Testing
4. Approval
5. Deployment
6. Verification

---

# 10. Authentication

AI ไม่ควรจัดการ Password
ของผู้ใช้โดยตรง

AI ไม่ควรเห็น:

- Password
- Password Hash
- MFA Secret
- Recovery Secret

---

# 11. Secrets

ห้ามเก็บ Secret ใน:

- Markdown
- Source Code
- Git Repository
- Chat
- Logs

ตัวอย่าง:

- API Key
- Database Password
- Access Token
- Private Key
- OAuth Secret

ต้องใช้ Secret Management System

---

# 12. Kao ID

Kao ID เป็นระบบ High Risk

AI สามารถ:

READ

และ

ANALYZE

ได้ตาม Permission

แต่การเปลี่ยนแปลง:

- Identity
- Authentication
- Authorization
- KYC
- Bank Account
- Security

ต้องผ่าน Explicit Approval

---

# 13. Payment

Payment เป็น High Risk

AI ห้าม:

- โอนเงิน
- เปลี่ยนบัญชีรับเงิน
- แก้ Transaction
- ลบ Transaction

โดยอัตโนมัติ

ต้องมี Explicit Approval

---

# 14. Data Deletion

AI ห้ามลบข้อมูลสำคัญโดย Default

ก่อนลบต้อง:

1. Identify Target
2. Explain Reason
3. Explain Impact
4. Check Dependencies
5. Propose
6. Explicit Approval
7. Execute
8. Verify
9. Audit

---

# 15. Approval

Approval ต้องระบุ:

- Action
- Target
- Scope
- Risk
- Expected Result

คำสั่งเช่น:

"ทำเลย"

สามารถใช้ได้เฉพาะเมื่อ
Proposal ล่าสุดมี Target และ Scope ชัดเจน

หากไม่ชัด:

AI ต้องถาม

---

# 16. Permission Expiration

สิทธิ์ระดับสูงควรมีอายุจำกัด

ตัวอย่าง:

Execute Permission

Valid:

Task Scope

เมื่อ Task เสร็จ
Permission ต้องสิ้นสุด

---

# 17. Task Scope

AI Permission ควรถูกจำกัดตาม Task

ตัวอย่าง:

Task:

แก้ Identity Profile UI

AI สามารถ:

- อ่าน Identity Code
- แก้ UI ที่เกี่ยวข้อง
- Run Flutter Analyze
- Run Test

AI ไม่ควรมีสิทธิ์:

- แก้ Payment
- แก้ Production Database
- แก้ Security Policy

---

# 18. Environment Separation

AI ควรแยก:

Development

Staging

Production

โดย Default:

AI ทำงานใน Development

ก่อนเข้าสู่ Staging หรือ Production
ต้องมี Approval

---

# 19. Sandbox

งานที่มีความเสี่ยง
ควรสามารถทำใน Sandbox ได้

ตัวอย่าง:

- Code Experiment
- Database Migration Test
- Automation Test
- AI Agent Test

ผลลัพธ์ต้องผ่าน Review
ก่อนนำไปใช้จริง

---

# 20. Audit

การกระทำสำคัญของ AI
ควรบันทึก:

- AI Identity
- User Identity
- Action
- Target
- Time
- Approval
- Result

---

# 21. AI Identity

AI แต่ละ Agent
ควรมี Identity แยกจาก User

ตัวอย่าง:

User:

Founder

AI:

Kao Developer Agent

หรือ:

Kao Research Agent

AI ไม่ควรปลอมเป็น User

---

# 22. Multi-Agent

ในอนาคตสามารถแบ่ง Agent:

Kao Architect Agent

Kao Developer Agent

Kao QA Agent

Kao Research Agent

Kao Documentation Agent

แต่ละ Agent ควรมี Permission ของตัวเอง

---

# 23. Permission Escalation

AI ห้ามเพิ่มสิทธิ์ของตัวเอง

การเพิ่ม Permission ต้องเกิดจาก:

User Approval

หรือ

Administrative Policy

---

# 24. Failure Rule

หาก Permission ไม่พอ:

AI ต้องหยุด

และแจ้ง:

- ต้องการ Permission อะไร
- เพื่อทำอะไร
- ความเสี่ยงอะไร
- Scope เท่าไร

จากนั้นรอ Approval

---

# 25. Security Priority

ลำดับความสำคัญ:

1. Security
2. Data Integrity
3. User Control
4. Correctness
5. Availability
6. Convenience

---

# 26. Core Principle

AI ต้องมี:

"Enough Permission To Work"

แต่ไม่ควรมี:

"Permission To Control Everything"

เป้าหมายคือ:

AI ทำงานแทนผู้บริหารได้มากขึ้น

โดยที่ผู้บริหารยังควบคุมสิทธิ์
และการตัดสินใจขั้นสุดท้ายได้เสมอ