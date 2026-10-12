# Kao ID R6C — Contact change requests

## Install
Apply after R6B (user-reported baseline: analyzer clean, 85 localization tests).
Back up lib and test. Extract this ZIP at the Flutter project root, then run:

```powershell
flutter gen-l10n
flutter analyze
flutter test test/localization
flutter run -d chrome --web-port=7357 --dart-define-from-file=.env
```

## Implemented
- Email verification detail → Change email.
- Confirmed phone detail → Change phone. Existing initial phone verification is retained.
- Shared change page and repository: current contact, new destination, password, optional registered TOTP factor selection/code, submit/resend, pending status, refresh.
- Password checked with a separate in-memory Supabase client. The mutation uses that freshly authenticated client's token, never a saved password or a privileged key.
- Owner ID checked before/after request. Authenticator code required when verified TOTP factors are present.
- Temporary session is signed out with local scope and disposed; the application client is not assigned this session.
- New email confirmed through Supabase confirmation links. Follow all emails required by the project's Secure email change setting, then Check again.
- New phone confirmed with phoneChange OTP; a successful verify response alone is never completion. A subsequent server read must match the target and confirmed timestamp.
- Phone destination hint survives reopening, stored per owner in SharedPreferences. This is a non-authoritative local hint, never verification evidence. It is removed after observed confirmation.
- Thai/English strings, loading/error/pending/success, 60-second UI cooldown, clear password/code fields after submission.
- Password-only and password + TOTP accounts supported. OAuth-only accounts without a password must complete existing account recovery/set-password flow first. Other MFA factor types are not implemented by this page; Auth remains responsible for enforcing its MFA policy.
- No database schema, RLS or provider settings changed. No real email/SMS sent during development.

## Validation evidence and limits
Added 7 controller tests + 4 bilingual narrow-screen widget tests. Existing tests are retained.
Static checks performed on ARB parity, translation references, local imports and ZIP contents.
Flutter/Dart were not available on PATH in this workspace; these new tests and analyzer have NOT been executed here. The earlier 85-test result applies to R6B, not this patch.

## Required live configuration / acceptance checks
These are open checks, not claims of production completion:
1. Email confirmation enabled; Secure email change enabled so both old and new addresses confirm when applicable.
2. SMS provider enabled, phone confirmation enabled; verify actual SMS delivery.
3. Email/SMS server rate limits, OTP expiry and attempts configured. UI cooldown is only UX and can be bypassed.
4. Email/phone changed security notification templates enabled and delivery tested.
5. Correct Site URL and allowed redirects for localhost:7357 and production. This page uses server confirmation links and then explicitly refreshes status; it does not require the redirected page to log the user in.
6. Test real request → old and new confirmation → refreshed current value → sign-in with new contact; old value must no longer sign in where applicable.
7. Test wrong/expired/replayed OTP, wrong password/TOTP, duplicate contact, network failure, reload and account switch.
8. Verify existing Auth-to-profile/verification sync triggers continue to update the correct fields after changes.
9. Test the project's session policy: a temporary password login may interact with single-session enforcement. If single-session enforcement is enabled, this workflow needs corresponding backend/session design before release.
10. The password/TOTP check is enforced by this application flow, NOT a project-wide guarantee that an existing bearer token cannot call Auth updateUser directly. A server-enforced recent-auth policy for every contact-change entry point remains a separate backend gate. Do not call R6 or production security complete on this patch alone.

## Manual UI sequence
Email: KYC → Email → Change email → enter new address/password (+TOTP if enabled) → submit → confirm required emails → Check again.
Phone: KYC → Phone (confirmed) → Change phone → enter new number/password (+TOTP) → submit → enter SMS OTP → verify. Returning to detail reloads authoritative status.
To resend, keep the same destination and enter password again after the waiting period.
No fake cancel action is shown: leaving the page does not cancel a pending server request.

## References checked
https://supabase.com/changelog
https://supabase.com/docs/reference/dart/auth-updateuser
https://supabase.com/docs/reference/dart/auth-signinwithpassword
https://supabase.com/docs/reference/dart/auth-mfa-challengeandverify
https://supabase.com/docs/guides/auth/auth-email-templates
