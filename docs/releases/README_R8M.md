# R8M — Actual verification status and timeline

Apply after R8L languages + R8C fix. No database migration and no approval/state changes.

- Hub document status comes from the latest non-deleted document of that type, not the aggregate verification flags.
- Missing document: no document submitted. Failed/loading query: status unknown.
- No bank record: no bank accounts yet. Manual review remains pending.
- Passport/residence show no submission separately from another pending identity request. Existing one-pending-request rule stays intact.
- Pending guidance is shown only for a pending document, not rejected/approved documents.
- Email hub/detail refresh uses authenticated server getUser, preserving the existing optional verification/change-email flows.
- History combines officer logs, dated identity submissions, dated bank submissions and server email/phone confirmation timestamps. Existing submit logs are deduplicated. Submission is never approval.
- Auth entries describe confirmation of the current contact. This does not reconstruct older email-change events that were never logged.
- History load failure stays an error with retry, not an empty-history assertion. Responses from a changed account are rejected.
- Uses existing localized labels, preserving all seven languages. No ARB replacement required.

Validation here: source/translation-reference checks and read-only database checks. Flutter/Dart are unavailable here; the included regression tests have NOT been run here.

Run on Windows:
```powershell
flutter analyze
flutter test test/localization/status_r8m_test.dart
flutter test test/localization
```
Restart the app. For the account with only a pending national ID, expect: national ID pending; passport/residence no document submitted; bank no accounts; email confirmed if server confirms it. History should show the actual national ID submission and current email confirmation date. The historical submission remains pending even after approval; the separate officer event records the later result.

Real approval, expired-document renewal and SMS delivery are not completed by this display correction.
