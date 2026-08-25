# Kao Brain Database Migration Plan

## 1. Purpose

กำหนดมาตรฐานสำหรับการสร้าง
และเปลี่ยนแปลง PostgreSQL Database
ของ Kao Brain

เป้าหมาย:

- Schema มี Version
- ทุกการเปลี่ยนแปลงมี Migration
- ตรวจสอบย้อนหลังได้
- ลดความเสี่ยงจาก Manual Change
- รองรับ Development / Staging / Production

---

# 2. Database Principle

Database Schema ต้องเปลี่ยนผ่าน Migration

ห้ามแก้ Production Database
ด้วย Manual SQL
โดยไม่มี Migration Record

---

# 3. Database

Initial Database:

PostgreSQL

Provider ยังไม่ถูก Lock

สามารถใช้:

- Supabase
- Managed PostgreSQL
- Self-hosted PostgreSQL

โดย Application ต้องไม่ผูกกับ Provider โดยตรง

---

# 4. Environment

แยก Database เป็น:

Development

Staging

Production

แต่ละ Environment ต้องมี:

- Database
- Credentials
- Configuration
- Migration State

แยกจากกัน

---

# 5. Migration Version

Migration ต้องมี Version

ตัวอย่าง:

001_initial_schema

002_add_proposals

003_add_approvals

004_add_agents

---

# 6. Migration Naming

รูปแบบ:

NNN_description

ตัวอย่าง:

001_initial_schema

002_add_task_dependencies

003_add_proposals

004_add_approvals

005_add_agents

---

# 7. Initial Migration

Migration แรก:

001_initial_schema

ควรสร้าง Core Tables:

- projects
- contexts
- decisions
- tasks
- task_dependencies
- knowledge
- ideas
- business_rules
- architectures
- proposals
- approvals
- agents
- agent_permissions
- document_references
- events
- changes
- audit_logs

---

# 8. Migration Order

ลำดับต้องคำนึงถึง Foreign Key

ตัวอย่าง:

projects

↓

contexts

decisions

tasks

↓

task_dependencies

↓

proposals

↓

approvals

---

# 9. UUID

Primary Key ใช้ UUID

ตัวอย่าง:

id UUID PRIMARY KEY

UUID Generation
ควรจัดการโดย Database
หรือ Application ตาม Architecture

---

# 10. Foreign Keys

Foreign Key ต้องกำหนด
สำหรับ Relationship ที่ชัดเจน

ตัวอย่าง:

tasks.project_id

→

projects.id

proposals.task_id

→

tasks.id

approvals.proposal_id

→

proposals.id

---

# 11. Referential Integrity

Database ต้องป้องกัน:

- Orphan Records
- Invalid References
- Broken Relationships

Foreign Key ต้องกำหนด
Delete Policy อย่างชัดเจน

---

# 12. Delete Policy

Default:

RESTRICT

สำหรับข้อมูลสำคัญ

ไม่ควรใช้:

CASCADE

โดยไม่วิเคราะห์ผลกระทบ

ข้อมูล Historical
ควรใช้:

- archived
- deprecated
- revoked
- disabled

แทนการ Delete

---

# 13. Initial Indexes

ควรสร้าง Index สำหรับ:

- project_id
- status
- created_at
- updated_at
- task_id
- proposal_id
- agent_id
- entity_type
- target_id

แต่ไม่ควรสร้าง Index ทุก Column
โดยไม่มีเหตุผล

---

# 14. Unique Constraints

ข้อมูลที่ต้องไม่ซ้ำ
ควรมี Unique Constraint

ตัวอย่าง:

projects.slug

agents.agent_key

---

# 15. NOT NULL

Field ที่จำเป็นต้องมี
ควรกำหนด NOT NULL

ตัวอย่าง:

project.name

task.title

proposal.title

agent.agent_key

---

# 16. Default Values

Field ที่มี Default
สามารถกำหนด Database Default

ตัวอย่าง:

status

created_at

updated_at

แต่ Business Logic สำคัญ
ควรอยู่ใน Application Layer

---

# 17. Timestamp

ใช้มาตรฐานเดียวกัน:

created_at

updated_at

Timestamp ควรเก็บเป็น UTC

Application แสดงตาม Timezone
ของ User

---

# 18. Migration Transaction

Migration ที่สามารถทำแบบ Transaction ได้
ควรทำภายใน Transaction

เป้าหมาย:

สำเร็จทั้งหมด

หรือ

Rollback ทั้งชุด

---

# 19. Non-Transactional Migration

บาง Operation อาจไม่สามารถทำ
ภายใน Transaction ได้

กรณีนี้ต้องระบุใน Migration
และมี Deployment Plan เพิ่มเติม

---

# 20. Backward Compatibility

Migration ที่มีผลต่อ API
ต้องพิจารณา:

Old Client

และ

New Client

สามารถทำงานร่วมกัน
ในช่วง Transition

---

# 21. Expand and Contract

การเปลี่ยน Schema ที่มีความเสี่ยง
ควรใช้:

Expand

↓

Migrate

↓

Switch

↓

Contract

ตัวอย่าง:

เพิ่ม Column ใหม่

↓

Application รองรับทั้งสองแบบ

↓

ย้ายข้อมูล

↓

เปลี่ยน Application

↓

ลบ Column เก่าใน Migration ภายหลัง

---

# 22. Data Migration

หากต้องย้ายข้อมูล:

- Backup
- Validate
- Migrate
- Verify
- Audit

ต้องมี Migration Record

---

# 23. Migration Testing

Migration ต้องทดสอบใน:

Development

ก่อน:

Staging

ก่อน:

Production

---

# 24. Production Migration

ก่อน Production:

1. Review Migration
2. Backup
3. Test
4. Estimate Impact
5. Deployment Plan
6. Rollback Plan
7. Approval

---

# 25. Rollback

Migration ควรมี Rollback Strategy

แต่ไม่ใช่ทุก Migration
สามารถ Rollback ได้อย่างปลอดภัย

ตัวอย่าง:

เพิ่ม Table

Rollback ง่ายกว่า:

ลบข้อมูลจำนวนมาก

ดังนั้น Migration ต้องระบุ:

Rollback Possible

หรือ

Rollback Requires Recovery

---

# 26. Backup

Production ก่อน Migration
ที่มีความเสี่ยง
ต้องพิจารณา Backup

Backup ต้องสามารถ Restore ได้

และควรมีการทดสอบ Restore

---

# 27. Migration Lock

ระบบควรป้องกัน
ไม่ให้ Migration หลายตัว
ทำงานพร้อมกัน

ต้องมี Migration Lock
หรือกลไกเทียบเท่า

---

# 28. Migration History

Database ต้องมี Table
สำหรับบันทึก Migration

ตัวอย่าง:

schema_migrations

Fields:

- version
- name
- applied_at
- checksum

---

# 29. Checksum

Migration ที่ถูก Apply แล้ว
ไม่ควรถูกแก้ไขย้อนหลัง

Checksum สามารถใช้ตรวจว่า
ไฟล์ Migration เปลี่ยนหรือไม่

---

# 30. Immutable Migration

เมื่อ Migration ถูก Apply
ใน Environment ใดแล้ว

ไม่ควรแก้ไฟล์เดิม

หากต้องการแก้:

สร้าง Migration ใหม่

---

# 31. Development Workflow

Developer:

Create Migration

↓

Run Local Database

↓

Test

↓

Commit Migration

↓

Code Review

---

# 32. Staging Workflow

Development PASS

↓

Deploy Migration

↓

Run Tests

↓

Verify Data

↓

Application Integration Test

---

# 33. Production Workflow

Staging PASS

↓

Backup

↓

Approval

↓

Apply Migration

↓

Verify

↓

Monitor

↓

Record Result

---

# 34. Migration Audit

ทุก Migration ต้องบันทึก:

- version
- name
- environment
- executed_at
- executed_by
- result

---

# 35. Sensitive Migration

Migration ที่เกี่ยวข้องกับ:

- Identity
- Authentication
- Authorization
- KYC
- Payment
- Security
- Production Data

ต้องมี High Risk Review

---

# 36. Database Credentials

Database Credential ต้องไม่อยู่ใน:

- Git
- Markdown
- Source Code
- Logs

ใช้:

Environment Variables

หรือ

Secret Manager

---

# 37. Local Development

Developer สามารถใช้:

Local PostgreSQL

หรือ

Development Database

ห้ามใช้ Production Credential

---

# 38. Test Data

Test Data ต้องแยกจาก Production Data

ห้ามนำข้อมูล Sensitive จริง
มาใช้ใน Development
โดยไม่มี Data Protection Policy

---

# 39. Seed Data

Seed Data สามารถใช้สำหรับ:

- Development
- Automated Testing

แต่ Production Seed
ต้องได้รับการควบคุมอย่างชัดเจน

---

# 40. Schema Validation

หลัง Migration ต้องตรวจ:

- Tables
- Columns
- Constraints
- Indexes
- Foreign Keys
- Permissions

---

# 41. Application Compatibility

Migration ต้องตรวจว่า
Application Version ที่ใช้งานอยู่
รองรับ Schema ใหม่

---

# 42. Deployment Order

กรณีทั่วไป:

1. Database Expand
2. Application Deploy
3. Data Migration
4. Verification
5. Database Contract

---

# 43. Failure Handling

หาก Migration Fail:

STOP

↓

เก็บ Error

↓

ตรวจ Database State

↓

ไม่ดำเนิน Migration ซ้ำ
โดยไม่ตรวจสอบ

↓

เลือก:

Rollback

หรือ

Recovery

---

# 44. Production Rule

ห้าม:

- DROP TABLE แบบไม่มี Approval
- DELETE Production Data แบบไม่มี Approval
- ALTER Sensitive Schema แบบไม่มี Review
- Manual SQL โดยไม่มี Record

---

# 45. Future Tool

Migration Tool
สามารถเลือกภายหลัง เช่น:

- Prisma Migrate
- Drizzle Kit
- Flyway
- Liquibase
- Supabase Migrations

แต่ Database Contract
ต้องไม่ผูกกับ Tool ใด Tool หนึ่ง

---

# 46. Initial Migration Plan

Phase 1:

001_initial_schema

Phase 2:

002_indexes_and_constraints

Phase 3:

003_proposal_approval

Phase 4:

004_agent_permission

Phase 5:

005_audit_events

ชื่อจริงสามารถปรับได้
เมื่อเริ่ม Implementation

---

# 47. Verification Checklist

ก่อนถือว่า Migration สำเร็จ:

- [ ] Migration Applied
- [ ] Schema Correct
- [ ] Foreign Keys Correct
- [ ] Indexes Correct
- [ ] Constraints Correct
- [ ] Application Starts
- [ ] API Health Check PASS
- [ ] Tests PASS
- [ ] Data Integrity PASS
- [ ] Audit Recorded

---

# 48. Core Principle

Database Change

ไม่ใช่แค่:

"รัน SQL"

แต่คือ:

Plan
→
Migration
→
Review
→
Backup
→
Apply
→
Verify
→
Audit

---

# 49. Source of Truth

Migration Files
คือ Source of Truth
สำหรับ Database Schema History

Database State
ต้องสามารถตรวจสอบย้อนกลับ
ไปยัง Migration ได้

---

# 50. Final Principle

Kao Brain Database
ต้องสามารถ:

สร้างใหม่ได้

ตรวจสอบได้

Migrate ได้

Recover ได้

และ Audit ได้

โดยไม่ขึ้นกับคนใดคนหนึ่ง