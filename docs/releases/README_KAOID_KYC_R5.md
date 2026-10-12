# Kao ID R5 — KYC hub and isolated loading

Install after R4 and its test fix. This ZIP does not overwrite existing tests,
profile, password, locale selection, logout, routes, or Supabase configuration.
ARB files include R4 keys; merge manually if you added your own keys afterwards.

## PowerShell in project root
```powershell
$backupItems = @('lib', 'test')
$backupName = 'kaoid_before_R5_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path $backupItems -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_kyc_R5.zip -DestinationPath . -Force
flutter gen-l10n
flutter analyze
flutter test test/localization
```
If commands pass, expected count is 74 tests (previous 69 plus 5).
Flutter could not be run in the author's environment; this is expected, not a reported result.

## Important database dependency
The connected database lacks authenticated SELECT on all five KYC tables.
This patch restores the menu independently of those reads. Statuses can still be unavailable
until the read grants are approved and repaired. Do not interpret that as verified or absent data.
The reviewed SQL proposal is docs/kyc_read_access_R5_REVIEW.sql; it ends ROLLBACK.
Extracting this ZIP does not run SQL or change the database.

## Manual acceptance
1. /identity/verification: Thai/English, 320px and desktop, text enlarged.
2. Menus remain reachable during failed loads. Return from details refreshes state.
3. History failed read shows retry, never 'no history'.
4. After database repair, real status and latest request appear.
5. Email/phone/forms remain existing implementations; audit those in the next batch.

## Rollback
Restore lib and test from the backup; regenerate l10n. The backup must match R4.
For an exact rollback remove newly-added kyc_status_label.dart and
 test/localization/kyc_sections_r5_test.dart before restoring (they did not exist in R4).
