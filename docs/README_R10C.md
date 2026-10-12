# R10C — Real account references, audit display and Owner request queue

Install over R10B + R10B fix. R10B was confirmed by the user: analyze clean, 11 targeted tests, 254 localization tests, runtime working.

## Included
- Persisted, server-generated ACC references for existing and newly created profiles. UUID remains the relational identity; Kao ID remains separately issued after KYC. ACC is a lookup reference, never a credential.
- Owner exact member search accepts ACC, UUID, email or Kao ID through the existing RPC. Staff assignment continues using the resolved UUID.
- Updated admin hub, member fields and staff history; copy controls, readable 24-hour local date/time with explicit UTC offset. Missing names and historical role snapshots show a dash.
- New governance/account audit events capture the actor's display name and roles at event time. Old events are not backfilled with guessed historical roles. Client writes, updates and deletion of governed audit events are denied by the trigger.
- Owner request queue: pending/cancelled/rejected/approved filters and 30-row cursor pagination.
- Request details: table-backed total orders/disputes, wallet balances/holds, pending KYC count, active staff assignment count, history.
- Owner may reject a pending request with a reason, after confirmation. Repeat rejection does not duplicate the event; member sees rejection and reason; in-app notification is emitted.
- Seven languages, with Chinese fallback ARB retained.

## Scope and remaining work
This is NOT the completed account lifecycle. There is no close/reopen/restore-ID endpoint or approval action in this package. The capability reports close_ready=false, and the UI explains closure is unavailable. Raw totals are not a declaration that obligations have been cleared.

Still required before closure can be enabled:
1. Inspect and define terminal states across orders, payment/refund/withdrawal/escrow, disputes and organization/service obligations; lock/check them again atomically at closure.
2. Implement server enforcement for every connected protected operation, session revocation and stale access-token denial. R9F guards do not cover every service or invalidate all Auth sessions.
3. Preserve the original Kao ID and necessary identity/audit records; explicitly deactivate staff/delegated/service rights. Define retention and document deletion rules.
4. Provide limited return/recovery access, fresh identity proof and authorized review before reactivating the original Kao ID. Email, phone or document-number equality alone must never restore identity. No automatic staff or service restoration.
5. Real end-to-end testing with independent user and Owner/reviewer accounts, stale sessions, retries and access denial.

The remaining work is not hidden behind an enabled button. Do not describe this ZIP as complete account closure or Kao ID recovery.

## Database
Already deployed on the connected project:
- owner_request_preflight_and_real_account_refs_r10c
- protect_historical_account_audit_r10c
The database files are review copies; do not rerun them on the already migrated project.

## Validation
SQL regression passed in a rolled-back transaction: real ACC lookup, Owner queue/details, member access denial, self-decision denial, spoofed audit denial, account-code edit denial, rejection idempotency, actor role snapshot, member-visible reason and unchanged account state.
Existing records: 2 profiles and 2 references when checked; do not hardcode these counts in UI.
Security advisors reviewed: private account-reference table deliberately has RLS with no client policies or direct grants. Existing project-wide security findings remain a separate backlog.
ARB key parity and localization references checked. Flutter and Dart are unavailable here; new widget tests have NOT been run. No account was closed, no staff permission was changed, no real request was rejected by testing, and no email was sent.

## Install and verify
Run flutter gen-l10n, flutter analyze, flutter test test/localization/owner_requests_r10c_test.dart, then flutter test test/localization.
Owner: Home → Kao ID admin center → Account requests.
Use a test member to submit a request; Owner opens the request, checks data and rejects with a reason; member reloads and verifies the result and notification. Do not use real account closure for this check.
