# R10B — Account lifecycle request intake

## Scope
Adds Settings → Account closure and return. Authenticated members can submit a closure request with a reason, see their latest 20 requests and cancel a pending request. One pending request per profile; retries reuse it. Owner cannot close through this route. A closed profile can submit a recovery request through the same backend, but reopening and identity recovery are NOT implemented by this patch.

The request is real and persisted in Supabase. It does not immediately close, delete, restore, approve KYC, issue/reassign a Kao ID, or change staff roles. Existing confirmation email flow is untouched. Phone OTP is still awaiting real testing. No domain is required to test the request page on localhost.

## Installation
Apply over R10A + R10A fix. ZIP includes changed source, eight ARB files for seven languages including Chinese fallback, and new widget tests. Run flutter gen-l10n, flutter analyze, flutter test test/localization/lifecycle_r10b_test.dart, then flutter test test/localization.

The SQL intake migration is already installed on the connected project. database/requests.sql is the deployed source for review, not a script to re-run on that project.

## Verification performed here
- SQL regression passed in one transaction rolled back in full: own submission and snapshot; duplicate suppression; account unchanged; one notification; cross-account read/cancel denied; Owner protected; client self-approval denied; cancellation audit idempotent; anonymous access denied; recovery request leaves closed status unchanged.
- All eight ARB files parse and have matching keys; all localization references in new code exist.
- Security advisor reviewed: private request table deliberately has no client RLS policies and no table grants; operations go through authenticated, ownership-checked RPCs. Existing project-wide security findings remain outside this patch.
- Flutter/Dart unavailable in this environment. Widget tests were written but NOT run here.
- No real account was closed or restored; no real KYC decision or email was sent.

## Remaining work — do not mark account closure/recovery complete
1. Owner processing queue with explicit checks for outstanding obligations; reject with reason or close after reauthentication and required checks.
2. Closing must atomically disable account use and staff/service permissions, preserve original Kao ID and audit trail, and enforce session/access restrictions. R9F does not yet revoke all Auth sessions.
3. Return in limited mode; identity evidence matched through the central KYC process. Email/phone matches alone MUST NOT attach another identity or reactivate an old Kao ID.
4. New KYC proof and authorized review before reactivating the original Kao ID; no duplicate identity or automatic staff/service restoration.
5. Retention/deletion policy and user-facing disclosure; retention is not a promise to store every document forever.
6. Real email event sending stays deferred until provider configuration; existing account confirmation email already passed per user. SMS OTP, document expiry/renewal and load testing remain open.

This patch provides request intake only. It does not add an Owner decision UI or a complete closed-account login/recovery entry flow.
