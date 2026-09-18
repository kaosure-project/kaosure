# Kao ID Idea Bank

This file preserves deferred product and architecture concepts without keeping dead source code.

## Purpose

Active source code contains only behavior that is wired to the current canonical architecture and database contract. Deleted legacy implementations remain recoverable from Git history.

## Deferred concepts

### Specialized document experiences

**Concept:** Dedicated UI experiences for Thai ID cards, passports, and residence permits.

**Purpose:** Provide document-specific validation, guidance, capture UX, and future OCR/MRZ assistance while keeping Identity as the owner of `identity_documents` and `document_files`.

**Why deferred:** Legacy KYC submission classes were built around separate document models and disconnected submission methods. The canonical database uses `identity_documents` rather than separate `identity_cards`, `passports`, or `residence_permits` tables.

**Reconsider when:** The canonical Identity upload flow is complete and each specialized UI can write through the same Identity repository contract without duplicating document ownership.

### Automated document extraction

**Concept:** OCR/MRZ-assisted extraction and validation.

**Purpose:** Reduce manual entry and improve document quality checks.

**Why deferred:** Extraction must not become the source of truth before document upload, consent, security, retention, and review policies are production hardened.

**Reconsider when:** Identity/KYC E2E tests, privacy controls, and document storage lifecycle are verified.

### Bank identity verification

**Concept:** Verify that a bank account belongs to the same verified person or organization.

**Purpose:** Support settlement, fraud prevention, and future financial services.

**Why deferred:** Bank verification needs its own canonical ownership and secure backend contract. It must not remain as an unimplemented KYC client method.

**Reconsider when:** The bank-account schema, provider integration, name-match rules, audit trail, and regulatory requirements are finalized.

### Contact verification expansion

**Concept:** Evolve phone verification into a broader contact-verification capability.

**Purpose:** Centralize verified phone/email/contact claims for downstream Kao services.

**Why deferred:** Current phone verification already exists and should be stabilized before structural renaming.

**Reconsider when:** Auth, sessions, recovery, and contact claims share a documented contract.

### Federation and service claims

**Concept:** Downstream services consume Kao ID claims/scopes instead of reading raw identity evidence.

**Purpose:** Keep Marketplace, Auction, KaoPay, and future applications decoupled from sensitive KYC documents.

**Why deferred:** Requires explicit service identity, consent/scope, token/claim, revocation, and audit contracts.

**Reconsider when:** Kao ID issuance and lifecycle are production verified.
