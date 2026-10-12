# Kao ID R6B — contact verification foundations

Install after R6A/R5. Existing dashboard/navigation/auth routes and user test fixes are preserved.
This batch improves existing contact verification, not the entire R6 release scope.

## Changes
- KYC email page uses existing AuthNotifier resend/refresh (no duplicated Auth client in UI).
- Email refresh stays on the detail page, with confirmed/unconfirmed/unknown states.
- Removes the unverified claim that email links always expire in 30 minutes.
- Phone repository isolates SDK calls; controller checks getUser after OTP.
- New phone is pending separately from the current phone. Only a matching confirmed server
  number completes the pending flow. No optimistic isVerified=true.
- Thai mobile input normalizes to +66; explicit international numbers accepted structurally.
- Prevents double requests, suppresses raw provider messages and guards disposed state.
- Resend uses phoneChange. Local 60-second cooldown survives actions within the page;
  it is UX only and resets after page disposal. Server rate limits remain required.
- Thai/English contact-page labels, loading/error/refresh and large-text layouts.
- New autoDispose phone controller clears pending OTP when page leaves. Re-enter and request
  a fresh code if needed; actual server cooldown still applies.

## Install in PowerShell
```powershell
$backupName = 'kaoid_before_R6B_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib,test -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_contacts_R6B.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```
11 new tests; expected total 85 if the previous 74 remain. Flutter NOT run here.
Static checks cover imports, preserved translation keys and bilingual key parity.
No Supabase settings changed; no real email/SMS sent during authoring.

## Manual verification before calling R6 complete
- SMTP delivery, callback allowlist and actual email-link expiry/configuration.
- SMS provider enabled/funded, destination delivery (Thailand); correct sender settings.
- Actual OTP length, expiry, server rate limits, repeated failed attempts, replay and throttling.
- Valid OTP updates auth confirmation and existing server synchronization to verifications.
- Bad/expired code never confirms new phone. Old verified number remains identified separately.
- Reopen/refresh after a link in another tab; sign out during a pending request.
- Secure contact-change reauthentication and notifications still require server-side design/audit.
  Existing phone-change API is retained; do not claim recent-auth enforcement from this UI.
- Email address change itself is NOT added in R6B; retain as next explicit subtask.
- Browser/Flutter runtime E2E must be tested on the user's machine.

## Remaining R6 queue
R6C: inspect real Auth settings and test provider delivery; secure email/phone changes,
reauthentication, notifications, server rate limits and recovery cases.
Do not mark whole R6 complete from unit/widget results alone.

## References
https://supabase.com/docs/reference/dart/auth-updateuser
https://supabase.com/docs/reference/dart/auth-resend
https://supabase.com/docs/reference/dart/auth-verifyotp

## Rollback
Restore lib/test backup; remove newly added phone_verification/domain and data files and
contact_verification_r6b_test.dart if they were absent before this batch; regenerate l10n.
