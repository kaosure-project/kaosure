# KaoSure Project Constitution

Version: 1.0

---

# Purpose

KaoSure เป็น Circular Commerce Ecosystem ที่สร้างบน Kao ID

การตัดสินใจทุกอย่างต้องคำนึงถึง

- ความปลอดภัย
- ความน่าเชื่อถือ
- ความสามารถในการขยายระบบ
- การดูแลรักษาระยะยาว
- การออกแบบจากข้อมูลจริง

---

# Core Principles

1. Kao ID คือ Root Platform

ทุก Feature ต้องใช้บริการจาก Kao ID

ห้ามสร้างระบบ Identity ซ้ำ

---

2. Authentication แยกจาก Identity

Authentication

- Login
- Password
- Session
- MFA

Identity

- Profile
- Documents
- Verification

---

3. Business Logic

Business Logic ต้องไม่อยู่ใน Screen

---

4. Single Responsibility

1 File

1 Class

1 Responsibility

---

5. Shared Components

Widget ที่ใช้ซ้ำ

อยู่ใน shared/

---

6. Documentation First

การตัดสินใจสำคัญ

ต้องมี ADR

---

7. Business Rule First

Business Rule มาก่อน Code

---

8. Database First

ออกแบบ Database ก่อนเขียน API

---

9. Security by Default

ทุก Feature

ต้องคิดเรื่อง

Authentication

Authorization

Audit

Rate Limit

---

10. Future Ready

ทุก Feature

ต้องรองรับ

Marketplace

Auction

Wallet

Future Apps

โดยไม่ต้องรื้อ Architecture

---

Approved

Project Owner

AI Architect