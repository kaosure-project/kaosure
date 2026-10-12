# R9E — Kao ID administration navigation

Apply after R9C. The previously installed Owner reviewer database change remains in effect.

Implemented:
- Home administration entry opens /admin, a central hub for existing account lookup, staff management and KYC review.
- Account lookup renamed User accounts to distinguish central identity from Secondhand membership.
- Owner sees account/staff/review actions according to backend access responses. Reviewer can use /admin for review only. Ordinary members receive no privileged actions; target RPCs still enforce permissions.
- Existing account lookup links back to hub.
- Review empty-state explains that own requests require a different reviewer. This is a general rule, not a claim that the viewer has a pending request.
- Seven languages retained. Six focused widget tests added but NOT run here; Flutter unavailable.

User baseline: R9C flutter analyze clean, 11 targeted tests and 224 total tests passed.

Install: backup lib,test; extract kaoid_admin_hub_R9E.zip; flutter gen-l10n; flutter analyze; flutter test test/localization/admin_hub_r9e_test.dart; flutter test test/localization.

Runtime check: Home -> Kao ID administration -> User accounts / Staff management / Review documents. Owner's own pending document remains excluded from own review queue. Do not resend it.

## Completion ledger — not all Kao ID work is complete

1. Existing account lookup, staff grant/revoke and document review: implemented, real end-to-end review still pending with separate officer.
2. Suspension/restoration: database has active/suspended/banned/closed values but no dedicated mutation workflow was found. Before exposing controls, implement atomic reason/audit, protect Owner, check session and sensitive operations, define restoration semantics; changing a status flag alone is not a complete suspension.
3. KYC revocation: separate from rejecting a pending request; needs impact on identity eligibility, audit and renewal workflow. No control in this patch.
4. Account closure: request/cancel/processing with service obligations and retention rules, not immediate record deletion. Not in this patch.
5. Expiry reminders/replacement, SMS OTP, devices/sessions, privacy, notification preferences remain pending.
6. Secondhand buyers/sellers/shops/orders stay outside Kao ID account administration.
7. Owner can perform existing central duties without assigning self a staff role. No self-document approval exception.

No database migration or actual account-status change is included in this patch.
