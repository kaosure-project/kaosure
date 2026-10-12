# R9B — Owner staff assignment and revocation

Apply after R9A + R9A test fix. All seven languages preserved. New translations await native review.

Entry: Home -> Member administration -> Staff management. /admin/staff and existing /governance both open the new Owner-only page.

Find an existing member by exact email/account ID/Kao ID. Review displayed name, email and immutable account ID. Choose role, inspect configured permission codes and confirm. New UI assignments have no expiry; revoke when no longer needed. Existing expiry is displayed. Lists/history bounded to latest 100 records (not a complete archive).

Only direct Owner can assign/revoke through the repaired RPCs. Owner cannot assign roles to self or another owner record. Target must have confirmed email, active nondeleted account. KYC officer can be appointed before customer KYC to bootstrap review; this never approves their own KYC. Other roles still require approved KYC and active Kao ID. Staff cannot appoint staff through these RPCs.

KYC officer currently reviews national IDs only and cannot review own request. Passport/residence/bank review expansion remains next. Permission codes describe configured backend rights; this patch does not implement missing modules for every role. Member search remains Owner-only as in R9A. is_active_admin retains its previous KYC requirement; first KYC officer uses dedicated can_review_kyc_r7c authority, not a blanket admin bypass.

Reuses admin_roles/admin_assignments and activity_logs, replacing the broken admin_actions insert in assignment/revocation. No new duplicate audit table. Existing tables retain their access policies. Role mutations and logs are atomic. Same effective assignment and repeated revocation do not duplicate audit rows. Auth session changes hide page/modal data and reject stale responses.

Backend owner_staff_assignment_r9b migration installed. SQL source retained under database; no manual execution needed.

Rollback SQL tests passed: Owner assignment, idempotency, effective reviewer access, non-owner escalation denied, revoke/repeat revoke, permission disappears, KYC unchanged, exactly two audit events. Actual active staff count after rollback is zero. No staff actually appointed by the assistant. Advisor checked; existing project hardening backlog remains.

Flutter/Dart unavailable here. Included tests have NOT been run here.
Run flutter gen-l10n; flutter analyze; flutter test test/localization/staff_r9b_test.dart; flutter test test/localization.

User checkpoint preceding this patch: analyzer clean, home 7 tests, member 16 tests, total 204 passed. R9B is not covered by those results.
