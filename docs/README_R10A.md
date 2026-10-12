# R10A — In-app notifications and email outbox

Apply after R9F. Last user verified baseline: analyze clean, 4 R9F tests, 234 total tests passed.

## Installed
- Existing notifications table reused. Server-owned notices generated atomically with new identity requests, approvals/rejections, bank decisions, account suspend/restore events.
- Duplicate event key cannot generate a second notice/email job.
- Members cannot create fake notices or edit another account's notices. Own read acknowledgement only through guarded RPC.
- Home notification button loads when opened, on app resume and every 60 seconds while visible/resumed; unread count, latest 30 notices, read acknowledgement and refresh/error UI. This is in-app polling, not browser push.
- Seven-language event labels, dates displayed using UI locale.
- Private worker queue: email job leases, SKIP LOCKED, retry bound 5, stale-token completion denied. Automatic precheck jobs created disabled; no automatic approval.
- Email worker kaoid-mail-worker deployed with JWT verification AND a separate scheduler secret. Disabled unless configuration is complete. Nothing sent during tests.

## Email activation still required
The Auth confirmation-email system is separate from this application notification sender.
Set server-side Supabase Edge Function secrets (never in Flutter .env and never paste secrets into chat):
- RESEND_API_KEY: key for your configured Resend account
- KAOID_MAIL_FROM: verified sender address/domain
- KAOID_PUBLIC_URL: public HTTPS application URL (localhost will not work for recipients)
- KAOID_WORKER_SECRET: random scheduler authentication secret
- KAOID_MAIL_ENABLED=true only after configuration and test delivery are ready

Invoke via a trusted scheduler every minute, with valid server JWT Authorization and x-worker-secret. Scheduling is not installed in this patch because sender and public URL are not configured. Worker takes at most five messages per call. Keep all service credentials out of client code.
The current email is a generic seven-language notification with a site link, not KYC documents or rejection details. Provider accepted means sent, not delivered; bounce/delivery webhook and operational alerting remain future work.
Resend adapter is provided; no subscription/purchase has been made. If another mail provider is chosen, replace the adapter without changing event producers.

## Automation preparation, not a finished automatic KYC service
New identity requests get a disabled kyc_precheck job referring to the existing request UUID and rule_version=manual-v1. This is an extension point. No OCR/liveness/vendor connection, automated approval authority, automatic recovery of Kao ID, staffing allocation UI or high-load capacity guarantee is included.
Before enabling a vendor: define result schema/version, scoped worker permissions, claim/lease/retry behavior, evidence-access audit, manual fallback, and test on controlled cases. Workers must never change approval tables directly.

## Verification
SQL rollback regression passed duplicate-event prevention, own inbox/read mark, cross-account denial, fake-notification denial, claim and lease-token completion. No emails or real KYC decisions were made.
Initial missing SELECT grant discovered and corrected via notification_inbox_select_grant_r10a.
Flutter unavailable here: added localization/widget tests have not been run.

## Install
Back up lib,test then extract kaoid_notifications_R10A.zip.
flutter gen-l10n
flutter analyze
flutter test test/localization/notifications_r10a_test.dart
flutter test test/localization

Only future events create notices; no fake historical notification backfill. Existing requests and decisions are not changed or resubmitted.
Email jobs older than the safe automatic retry window require operational review; do not blindly resend old jobs after provider idempotency expires.

Trigger regression also passed synthetic submission -> notice + disabled precheck job, then rejection -> notice; all rolled back.
Private jobs table intentionally has RLS with no client policies (deny access); advisor reports this informationally. Existing unrelated security backlog remains.
