# R7B — Email display consistency

Patch after R7A (118 tests passed on the user's machine; analyzer clean).

## Root cause and change
The KYC hub used verifications.email_verified, while the email page used the current Auth user's emailConfirmed. These are different sources and can disagree.
Both screens now observe emailVerificationStatusProvider, derived from the existing Auth state. The hub calls the existing refreshCurrentUser flow on entry, refresh, and return from a child page. The detail page keeps its existing refresh and email-change flow.

Loading/failure/signed-out states display Unknown, not Not verified. Verified accounts no longer see instructions to follow a confirmation link or resend it. Thai and English reuse existing translations; no ARB files are replaced.

No database status is forced to true. No signup, OTP, email delivery or purchase authorization setting is changed. Auth confirmation remains the existing display convention: with signup auto-confirm enabled it is not by itself independent proof of email ownership. Separate server-side authorization/proof-of-ownership work remains in the roadmap. This patch aligns the two reported screens; it does not backfill KYC database fields or grant transaction permissions.

## Install
```powershell
$backupName = 'kaoid_before_R7B_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip'
Compress-Archive -Path lib,test -DestinationPath $backupName
Expand-Archive -LiteralPath .\kaoid_email_status_R7B.zip -DestinationPath . -Force
flutter analyze
flutter test test/localization
```

Flutter/Dart is not available to the assistant here: imports/localization references were inspected, but analyzer and the six new widget tests must be run locally. Existing 118 passing tests are the baseline, not a claim that the modified suite passed.

## Check in Chrome
Restart the running app (capital R in the Flutter terminal).
Open Identity verification: Email should match the Verify email detail page.
Return from detail: hub refreshes again.
Switch Thai/English: both statuses agree.
An unconfirmed test account must remain unconfirmed. Network errors must show Unknown and allow retry, not claim successful verification.

Email verification already reported successful by the user is preserved. Phone OTP remains pending real-provider testing. No other page is redesigned in this patch.
