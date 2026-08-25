# Kao ID ↔ Kao Brain Token Contract

## 1. Purpose

กำหนด Contract ระหว่าง Kao ID
และ Kao Brain สำหรับการส่ง Identity Context

เป้าหมาย:

Kao ID
→ Authenticate User
→ Issue Identity Token
→ Kao Brain Validate Token
→ Establish User Identity
→ Apply Authorization

---

# 2. Core Principle

Kao ID เป็น Source of Truth
สำหรับ Human Identity

Kao Brain ไม่สร้าง Identity ใหม่แทน Kao ID

Kao Brain เก็บเฉพาะ Identity Reference
ที่จำเป็นต่อการทำงาน

---

# 3. Responsibility

## Kao ID

รับผิดชอบ:

- Registration
- Authentication
- Identity Verification
- Account Status
- Session
- Identity Token

---

## Kao Brain

รับผิดชอบ:

- Token Validation
- Project Membership
- Authorization
- Permission
- Scope
- Agent Authorization
- Audit

---

# 4. Token Type

Initial Recommendation:

Signed Access Token

รูปแบบจริงสามารถเลือก:

- JWT
- Opaque Token

ตาม Security Architecture

---

# 5. Token Requirements

Token ต้องมี:

- Signature
- Issuer
- Audience
- Subject
- Issued At
- Expiration

---

# 6. Required Claims

ตัวอย่าง:

```json
{
  "iss": "kao-id",
  "aud": "kao-brain",
  "sub": "kao-user-id",
  "iat": 0,
  "exp": 0
}