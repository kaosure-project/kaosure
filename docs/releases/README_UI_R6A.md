# Kao ID R6A — Account layout

UI-only patch after R5. Uses the supplied Yahoo Japan screenshot as a layout reference:
brand/header, top category navigation, bounded two-column cards on desktop,
single column on narrow screens or enlarged text. Uses Kao ID colors and labels.
Only 2 existing Dart files replaced. No ARB/test/database/Auth/KYC state files replaced.
Existing R4 scrollUntilVisible test fix and R5 state braces remain intact.
No incomplete privacy/services/help buttons or fabricated connected accounts.
Existing logout remains in Settings. Email/phone implementation R6 is still pending.

## Install
```powershell
$backupName = 'kaoid_before_R6A_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_ui_R6A.zip -DestinationPath . -Force
flutter analyze
flutter test test/localization
```
No new localization keys; no gen-l10n needed if R5 generation already completed.

## Validation
Static imports and localization references checked against R4/R5.
Flutter analyzer/tests and visual rendering have NOT been run here.
Run existing 74 tests on the user's machine; inspect 320px/desktop, Thai/English,
large text, every top navigation item, card destinations and back navigation.
The patch preserves DashboardHomeContent's constructor/callback interface.

## Next
Complete email/phone verification using the existing Auth foundation. This layout
patch is not completion of OTP, contact changes, recovery or server-side limits.
