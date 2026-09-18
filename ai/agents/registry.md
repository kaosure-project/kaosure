# Kao AI Agent Registry

## Purpose

ทะเบียนกลางสำหรับ AI Agent ทั้งหมด
ที่ได้รับอนุญาตให้ทำงานภายใน Kao Ecosystem

Agent ทุกตัวต้องมี Identity, Role, Scope และ Permission
ตามที่กำหนดไว้ใน:

docs/security/ai_agent_identity.md

และ:

docs/security/ai_permission_model.md

---

# Agent Registry

## KAI-GEN-001

### Name

Kao General Agent

### Type

General

### Role

รับคำสั่งจากผู้บริหาร
วิเคราะห์ Intent
ค้นหา Context
ประสานงานกับ Agent อื่น
และสรุปผลกลับไปยังผู้บริหาร

### Scope

Kao Ecosystem

### Default Permission

READ
SEARCH
PROPOSE

### High Risk

ต้องได้รับ Explicit Approval

### Status

Active

---

# KAI-ARCH-001

## Name

Kao Architect Agent

### Type

Architect

### Role

วิเคราะห์และออกแบบ Architecture

### Responsibilities

- Architecture Analysis
- Technical Design
- Dependency Analysis
- Impact Analysis
- Architecture Review

### Scope

Architecture

### Default Permission

READ
SEARCH
PROPOSE

### Write Permission

ต้องได้รับ Approval

### Status

Active

---

# KAI-DEV-001

## Name

Kao Developer Agent

### Type

Developer

### Role

พัฒนาและแก้ไข Source Code

### Responsibilities

- Code Analysis
- Code Proposal
- Implementation
- Refactoring
- Unit Test
- Build Verification

### Scope

Kao ID และระบบที่ได้รับมอบหมาย

### Default Permission

READ
SEARCH
PROPOSE

### Write Permission

ต้องได้รับ Approval

### Execute Permission

เฉพาะ Development Environment

### Production

ไม่มีสิทธิ์โดย Default

### Status

Active

---

# KAI-QA-001

## Name

Kao QA Agent

### Type

QA

### Role

ตรวจสอบคุณภาพของระบบ

### Responsibilities

- Test Planning
- Test Execution
- Bug Analysis
- Regression Testing
- Integration Testing
- Quality Report

### Scope

Testing

### Default Permission

READ
SEARCH
PROPOSE

### Execute

สามารถ Run Test ได้ตาม Scope

### Write

ต้องได้รับ Approval

### Status

Active

---

# KAI-RES-001

## Name

Kao Research Agent

### Type

Research

### Role

ค้นคว้าและวิเคราะห์ข้อมูล

### Responsibilities

- External Research
- Technical Research
- Market Research
- Competitive Analysis
- Source Verification
- Research Summary

### Scope

Research

### Default Permission

READ
SEARCH
PROPOSE

### Source Code Write

ไม่มี

### Production Access

ไม่มี

### Status

Active

---

# KAI-DOC-001

## Name

Kao Documentation Agent

### Type

Documentation

### Role

จัดการและตรวจสอบ Documentation

### Responsibilities

- Documentation Analysis
- Documentation Proposal
- Documentation Update
- Documentation Consistency
- Knowledge Organization

### Scope

Documentation

### Default Permission

READ
SEARCH
PROPOSE

### Write

ต้องได้รับ Approval

### Delete

ไม่มีสิทธิ์โดย Default

### Status

Active

---

# Permission Matrix

| Agent | Read | Search | Propose | Write | Execute | Production |
|---|---|---|---|---|---|---|
| KAI-GEN-001 | ✓ | ✓ | ✓ | Approval | No | No |
| KAI-ARCH-001 | ✓ | ✓ | ✓ | Approval | No | No |
| KAI-DEV-001 | ✓ | ✓ | ✓ | Approval | Dev | No |
| KAI-QA-001 | ✓ | ✓ | ✓ | Approval | Test | No |
| KAI-RES-001 | ✓ | ✓ | ✓ | No | No | No |
| KAI-DOC-001 | ✓ | ✓ | ✓ | Approval | No | No |

---

# Agent Assignment Rules

## General Rule

Task ต้องถูกกำหนด Scope ก่อนมอบหมาย Agent

---

## Architecture Task

Default Agent:

KAI-ARCH-001

---

## Development Task

Default Agent:

KAI-DEV-001

---

## QA Task

Default Agent:

KAI-QA-001

---

## Research Task

Default Agent:

KAI-RES-001

---

## Documentation Task

Default Agent:

KAI-DOC-001

---

## Complex Task

KAI-GEN-001
สามารถประสานงานกับ Agent อื่นได้

ตัวอย่าง:

KAI-GEN-001
↓
KAI-ARCH-001
↓
KAI-DEV-001
↓
KAI-QA-001
↓
KAI-DOC-001

---

# Agent Delegation

Agent สามารถเสนอให้ Agent อื่นทำงานได้

แต่ต้องมี:

- Source Agent
- Target Agent
- Task
- Scope
- Permission
- Reason

การ Delegation ต้องสามารถตรวจสอบย้อนหลังได้

---

# Agent Selection

Kao Brain ควรเลือก Agent
จาก:

1. Task Type
2. Required Capability
3. Scope
4. Permission
5. Availability
6. Security Level

---

# Security Rule

Agent ห้ามเลือกตัวเอง
เพื่อเพิ่ม Permission

Agent ห้ามมอบ Permission ให้ตัวเอง

Agent ห้ามสร้าง Credential ให้ตัวเอง

Agent ห้ามเปลี่ยน Role ตัวเอง

---

# Status

Agent สามารถมีสถานะ:

- Active
- Suspended
- Disabled
- Archived

---

# Registry Change

การ:

- สร้าง Agent
- เปลี่ยน Role
- เปลี่ยน Scope
- เพิ่ม Permission
- ลด Permission
- Disable Agent

ต้องผ่าน Administrative Approval

---

# Model Independence

Agent ID ไม่ผูกกับ AI Model

ตัวอย่าง:

KAI-DEV-001

สามารถใช้:

GPT

หรือ

Claude

หรือ

Gemini

หรือ

Future AI Model

โดยไม่เปลี่ยน Agent Identity

---

# Future Agent Types

สามารถเพิ่ม Agent ในอนาคต เช่น:

- Security Agent
- Database Agent
- API Agent
- Product Agent
- Finance Agent
- Marketplace Agent
- KYC Agent
- DevOps Agent

แต่ทุก Agent ใหม่ต้องกำหนด:

- Identity
- Role
- Scope
- Permission
- Owner
- Security Policy

ก่อน Active

---

# Core Principle

Agent Registry คือทะเบียน

ไม่ใช่ Execution Engine

การมี Agent อยู่ใน Registry
ไม่ได้หมายความว่า Agent มีสิทธิ์ทำงานทุกอย่าง

Permission และ Task Scope
ยังคงเป็นตัวควบคุมการทำงาน