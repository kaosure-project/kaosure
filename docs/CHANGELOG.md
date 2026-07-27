# KaoSure Coding Standard

Version: 1.0

---

# Philosophy

- Readability over cleverness.
- Simplicity over complexity.
- Composition over inheritance.
- Feature-first architecture.
- Business rules belong to the Domain.

---

# Naming

## File

snake_case

Examples

register_controller.dart

identity_repository.dart

create_product_use_case.dart

---

## Folder

snake_case

Example

presentation

application

infrastructure

domain

---

## Class

PascalCase

Examples

RegisterController

IdentityRepository

AppTheme

---

## Variable

camelCase

Example

displayName

currentUser

bankAccount

---

## Constant

camelCase

Example

maxImageCount

defaultPageSize

---

# Folder Rules

Every feature follows

presentation/

application/

domain/

infrastructure/

No exceptions.

---

# Presentation Layer

Contains

- Screens
- Widgets
- Controllers
- Providers

Never access Supabase directly.

---

# Application Layer

Contains

- Use Cases

One business action per Use Case.

Examples

RegisterAccountUseCase

LoginUseCase

CreateProductUseCase

---

# Domain Layer

Contains

- Entities
- Value Objects
- Repository Contracts

No Flutter.

No Supabase.

No external packages.

---

# Infrastructure Layer

Contains

- Repository implementations
- Mappers
- DTOs

Only Infrastructure knows Supabase.

---

# Repository Rules

Presentation

↓

UseCase

↓

Repository Contract

↓

Repository Implementation

↓

Supabase

Never skip layers.

---

# Value Objects

Always immutable.

Validate inside constructor.

Never expose invalid state.

---

# Entity

Business object only.

No UI.

No Database code.

---

# Widgets

Reusable widgets go into

shared/

Feature-specific widgets stay inside the feature.

---

# Imports

Prefer relative imports inside the same feature.

Avoid unnecessary package imports.

---

# Comments

Write code that explains itself.

Add comments only when business rules need explanation.

---

# Error Handling

Never ignore exceptions.

Convert infrastructure exceptions into domain-friendly errors when appropriate.

---

# Testing

Every Use Case should be testable.

Business logic must not depend on Flutter.

---

# Principle

Small files.

Single responsibility.

Easy to understand.

Easy to maintain.