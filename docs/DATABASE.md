# KaoSure Database

Version: 1.0

---

# Database

Backend

- Supabase

Database

- PostgreSQL

Authentication

- Supabase Auth

---

# Database Layers

auth

Provided by Supabase

Contains

- users

---

public

Application Data

Contains all business tables.

---

storage

Supabase Storage

Contains

- avatars
- product_images
- documents
- chat_files

---

# Naming Convention

Tables

snake_case

Example

user_profiles

seller_levels

bank_accounts

device_sessions

---

Columns

snake_case

Example

created_at

updated_at

display_name

seller_level

---

Primary Key

UUID

Example

id UUID

---

Foreign Key

Always reference UUID.

Example

user_id

product_id

order_id

---

Timestamp

Every table should contain

created_at

updated_at

---

Soft Delete

deleted_at

Use when data should not be removed permanently.

---

# Kao ID

Tables

profiles

devices

bank_accounts

sessions

oauth_accounts

identity_logs

verification_requests

---

# Marketplace

Tables

products

product_images

categories

orders

order_items

wallet_transactions

shipping_addresses

reviews

favorites

notifications

reports

---

# Chat

Tables

chat_rooms

chat_messages

message_attachments

---

# Wallet

Tables

wallets

wallet_transactions

withdraw_requests

deposit_requests

---

# Audit

Tables

audit_logs

activity_logs

security_logs

---

# Database Rules

Never duplicate data.

Normalize data.

Use foreign keys.

Use indexes.

Enable Row Level Security.

---

# Migration

Every schema change must be created as a migration.

Never modify production tables manually.

---

Status

Foundation Complete