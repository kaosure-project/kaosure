# KaoSure Project Structure

Version: 1.0

---

# Root Structure

```
kaosure/

├── docs/
├── lib/
├── assets/
├── test/
├── web/
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── pubspec.yaml
└── README.md
```

---

# lib/

```
lib/

├── app/
├── core/
├── features/
├── shared/
└── main.dart
```

---

# main.dart

Application Entry Point.

Responsibilities

- Start application.
- Call bootstrap().

Never place business logic here.

---

# app/

Application Layer

```
app/

├── app.dart
├── bootstrap.dart
├── router.dart
├── theme.dart
└── providers.dart
```

Responsibilities

- Application startup
- Dependency initialization
- Routing
- Theme
- Global Providers

No Business Logic.

---

# core/

Shared Infrastructure.

```
core/

├── config/
├── constants/
├── errors/
├── exceptions/
├── interfaces/
├── network/
├── security/
├── services/
├── storage/
└── utils/
```

Core must never depend on Marketplace.

---

# features/

Business Features.

```
features/

├── kao_id/
├── marketplace/
├── wallet/
├── shipping/
├── chat/
├── payment/
└── notifications/
```

Every feature owns its business logic.

---

# Feature Structure

Example

```
kao_id/

├── application/
│
├── domain/
│
├── infrastructure/
│
└── presentation/
```

---

## application/

Contains

- Use Cases

Example

```
register_account_use_case.dart
```

---

## domain/

Contains

- Entities
- Value Objects
- Repository Contracts

No Flutter.

---

## infrastructure/

Contains

- Repository implementations
- DTOs
- Mappers
- External APIs

Supabase lives here.

---

## presentation/

Contains

- Screens
- Widgets
- Controllers
- Providers

Flutter UI only.

---

# shared/

Reusable UI.

```
shared/

widgets/

dialogs/

extensions/

themes/
```

No business logic.

---

# Dependencies

Presentation

↓

Application

↓

Domain

↓

Infrastructure

↓

Supabase

Never reverse dependency.

---

# Documentation

```
docs/

ARCHITECTURE.md

PROJECT_STRUCTURE.md

DATABASE.md

CODING_STANDARD.md

API.md

CHANGELOG.md

DEVELOPMENT_LOG.md
```

---

# Rule

Every new feature must follow this structure.

No exceptions.