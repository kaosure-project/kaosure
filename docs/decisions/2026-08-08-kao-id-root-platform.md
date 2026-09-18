# Kao ID Root Platform

## Date

2026-08-08

## Status

Approved

## Decision

Kao ID จะเป็น Root Platform ของ Kao Ecosystem

Kao ID ไม่ใช่เพียงระบบ Authentication ของ KaoSure Marketplace
แต่เป็นระบบ Identity และ Shared Platform ที่ Application อื่นสามารถนำไปใช้งานได้

## Reason

Kao Ecosystem จะประกอบด้วยหลาย Application ในอนาคต

ตัวอย่างเช่น:

- KaoSure Marketplace
- Auction
- First-hand Marketplace
- Kao Pay
- Agriculture
- Future Applications

การให้ Kao ID เป็น Root Platform ทำให้ Application เหล่านี้สามารถใช้ Identity กลางร่วมกันได้

## Architecture Principle

Kao ID เป็นระบบกลาง

Application อื่นเป็น Client หรือ Application ที่เรียกใช้ Kao ID

Marketplace ไม่ควรเป็นเจ้าของ Identity หลักของผู้ใช้

## Authentication

Authentication และ Identity ต้องแยกจากกัน

การ Login ไม่ได้หมายความว่าผู้ใช้มี Kao ID

Kao ID จะเกิดขึ้นเมื่อผู้ใช้ผ่านกระบวนการยืนยันตัวตนตามเงื่อนไขของระบบ

## Reusability

Kao ID ต้องถูกออกแบบให้ Application ภายนอกหรือ Application ในอนาคตสามารถเชื่อมต่อผ่าน API ได้

ระบบต้องไม่ผูกติดกับ Marketplace เพียงระบบเดียว

## External Services

บริการภายนอก เช่น:

- KYC
- Payment
- SMS
- Email
- Storage

ควรถูกออกแบบผ่าน Abstraction Layer

เพื่อให้สามารถเปลี่ยนผู้ให้บริการได้โดยไม่ต้องรื้อ Core System

## Impact

การตัดสินใจนี้มีผลต่อ:

- Authentication
- Identity
- KYC
- Profile
- Devices
- Sessions
- Bank Accounts
- OAuth
- API
- Security
- Future Applications

## Related Systems

- Kao ID
- KaoSure Marketplace
- Future Kao Applications

## Related Documents

- docs/architecture/
- docs/business_rules/
- docs/security/

## Approved By

Founder