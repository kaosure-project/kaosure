# Kao ID R11A — account restrictions, sessions, revocation and renewal

Requires the existing R10E installation. This ZIP includes the one-line R10E mounted fix.

## Implemented

- Central access checks distinguish active, closed, suspended, banned, temporarily_locked and unavailable accounts. Missing, revoked or expired Auth sessions are denied. Existing restrictive database/Storage policies use this gate.
- Suspending an account terminates its Auth sessions and refresh tokens. Restoring account status does not recreate old sessions. A newly signed-in restricted account sees an explanatory screen.
- Superseded public `approve_financial_verification` and `approve_business_kyc` RPCs are no longer callable by anon/authenticated clients. Personal-document and bank decisions use the existing central review queue. Business approval remains deferred.
- Security → Signed-in sessions: real `auth.sessions` metadata, up to 100 live sessions, end one other session or all other sessions with confirmation. The current session is retained. Missing metadata is —; this is not a historical-login or device-fingerprint system.
- Security → Document validity and renewal: document state, expiry, replacement entry points, revocation/expiry history.
- Owner → Members → Document validity and renewal: revoke approved/expired document with a reason. No self-revocation, no document deletion, one audit/notice on retry.
- If no valid primary evidence remains, the existing personal Kao ID is suspended. New evidence must pass the existing independent review before an automatically held ID is reactivated. A manually suspended identity is not automatically cleared by this mechanism. Residence evidence does not grant personal identity eligibility; bank checks remain separate.
- Renewal is allowed in the final 30 days, after expiry, revocation or rejection. It creates a new document/request, preserves the old evidence, and respects the single pending-request rule. Retained approved/expired/revoked identity numbers remain protected against approval for a different profile.
- The issuance RPC checks valid primary evidence even when a Kao ID already exists.
- Scheduled expiry runs at minute 5 each hour (UTC), processing up to 200 expired documents and 200 upcoming-expiry notices per run. Scheduled processing is bounded, not a large-volume capacity guarantee. Date validation in issuance/review does not wait for cron.
- In-web notices and event-email queue entries are created; the email worker remains subject to its existing provider/configuration requirements. This patch does not activate real email sending.
- Expiry uses an explicit system audit actor, not Owner's name. New manual history records store actor name/roles at the time of the event and the real account code.
- Same-account R10E recovery accepts previously approved evidence that has since expired for comparison. It does not treat an expired document as currently valid or accept revoked evidence as recovery history.
- New UI messages cover Thai, English, Japanese, Simplified Chinese, Burmese, Lao, Vietnamese and Chinese fallback. Five mutable search-path warnings were fixed; Auth trigger functions are no longer client-callable RPCs.

## Installed database changes

Already applied to the existing connected project. Do not paste SQL into the dashboard again as part of normal ZIP installation. The database files are a reviewable record, not an automatic installer. Deployment sequence:
1. hardening.sql
2. identity_lifecycle.sql
3. system_audit.sql
4. expiry_schedule.sql
5. recovery_compatibility.sql
6. function_hardening.sql
7. history_snapshots.sql
8. session_actor_guard.sql

## Verification performed here

- SQL transaction/rollback: real session list, cross-account denial, single-session revocation, idempotent retry, suspension session termination, restricted API gate, restoration and legacy RPC grants.
- SQL transaction/rollback: Owner-only revocation, self/cross-account denial, retained ID, expiry transitions and notice deduplication; actual replacement submission through the existing national-ID RPC, central review and same-ID reactivation; no staff restoration.
- SQL transaction/rollback: R10E recovery, cancellation, rejection, no generic-review bypass and unchanged Kao ID, with live-session fixtures; repeated with expired previous evidence.
- ARB key parity and all changed Dart localization references; Dart grammar parsing for changed code and tests.
- Schedule registration verified active. A completed scheduled run is not yet acceptance-tested.
- Security advisors checked. Private no-policy tables are intentional deny-all client access. Other legacy business/API and extension warnings plus leaked-password configuration still require review; this is not a clean full-project security certification.

**Flutter/Dart SDK is unavailable in this workspace. Flutter analyze and widget tests have NOT been run here. SQL fixture tests do not prove browser upload, real SMS, actual email delivery or real-user approval. No real account was suspended, closed, revoked or approved by the regression tests; they rolled back. Scheduled expiry will process eligible real records on its next run.**

## Install on Windows

```powershell
$backupName = 'kaoid_before_R11A_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib,test -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_hardening_R11A.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization/hardening_r11a_test.dart
flutter test test/localization
```

Restart the app after passing. If an existing session has been terminated, sign in again.

## Required real-app acceptance (test accounts)

1. Owner and regular member: confirm normal navigation; member cannot open Owner actions by URL.
2. Sign a test member into two browser profiles. Revoke the other session; verify its next API request is denied and its UI hides data. Current session stays usable. Retry is harmless.
3. Owner suspends a non-Owner test account; existing sessions are denied. A fresh sign-in sees restriction. Restore, sign in again, and check audit and permissions.
4. Submit real test images → independent officer opens them → approve/reject → member sees matching result → request Kao ID twice and get the same ID.
5. Owner revokes an approved test document with a reason. If another valid primary document exists, identity remains eligible; otherwise ID is held. Submit new evidence, review independently, verify same ID and no restored staff role.
6. With a dedicated fixture document near expiry, confirm renewal is offered; confirm expired evidence cannot be approved or used to issue an ID. Check cron history and exactly one notice per expiry event.
7. Close → fresh login → request recovery → new evidence → independent review → original ID. Test cancellation/rejection and old sessions too.
8. Test phone layouts and all seven languages, load error versus empty data, session/account switching during requests, and network retry.

Never change expiry dates or approval status of a real member merely to test the scheduler. Use isolated test data.

## Remaining gates — not claimed complete

- Browser end-to-end acceptance above and Flutter analyzer/tests on the user's machine.
- Real SMS OTP; real event-email provider/sender/scheduler/delivery monitoring. Auth confirmation email already works and is preserved.
- MFA, full historical login/security events, device trust, rate limits/CAPTCHA tuning, queue paging/claiming, monitoring/backup restore drills and load tests.
- A documented retention/deletion policy and its enforcement. No arbitrary retention duration or automatic deletion of KYC images was introduced.
- Closure for accounts with completed service history: existing conservative blockers remain until each service's settled-obligation rules are implemented.
- New-account UUID identity transfer, Business/Organization completion, fully automated KYC remain deferred.
- Service-specific enforcement of identity eligibility must be integrated when Marketplace is activated. Do not rely on a cached UI badge or solely on periodic expiry processing.

Sources consulted: https://supabase.com/docs/guides/auth/sessions ; https://supabase.com/docs/guides/cron/quickstart ; https://supabase.com/changelog.md
Advisors: https://supabase.com/docs/guides/database/database-linter
