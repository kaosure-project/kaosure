# Kao ID R6D — Verification document localization

Baseline: R6C installed by user; flutter analyze clean and 96 localization tests passed.
This patch has NOT been run with Flutter in the authoring environment.

## Completed in this patch
- Thai/English localization for national ID, passport, residence permit and bank verification details.
- Localized legacy verification tiles/sections, shared upload controls, file information, date-picker actions, status chips and inline validation.
- Passport display date uses MaterialLocalizations. Raw passport save exception is replaced with a localized user-facing error.
- Shared upload defaults resolve in build, allowing locale changes without recreating the app.
- Removed nested page/scroll wrappers in DocumentUploadCard; the parent page owns scrolling.
- Selected ID-card filenames now display even when file size was not supplied.
- Unknown StatusChip values render unknown rather than pretending no document was submitted.
- Residence permit upload remains unfinished; its formerly empty action is disabled and its status explains availability.
- Corrected upload copy: the current image picker accepts JPG/JPEG/PNG, not PDF. Removed unsupported 10 MB/encryption guarantees from this UI copy. No upload-size validation or encryption feature was implemented by this translation patch.
- Choosing a file is explicitly distinguished from submitting it.

## Validation
- 26 Dart presentation files updated.
- 159 added ARB entries including placeholder metadata; en/th parity and all referenced new localization getters checked.
- Static delimiter and const-expression checks passed. These are NOT Dart analyzer results.
- 11 regression/widget tests added, covering the four detail pages in both languages, unknown statuses, locale switching and unavailable residence action.
- Existing tests retained. Run flutter gen-l10n, flutter analyze and flutter test test/localization locally.

## Deliberately unfinished work — do not mark as complete
1. Deferred email ownership verification: signup/sign-in must remain available before verification. User confirms verification should occur when buying is requested. Current emailConfirmedAt may reflect automatic Auth confirmation and is not sufficient ownership proof under this policy.
2. Deferred phone verification: also optional at signup; real SMS/OTP testing is blocked and was explicitly deferred by the user.
3. UI discrepancy between KYC email summary and Auth-based detail remains an open data/verification-policy issue; this localization patch does not hide it by treating Auth confirmation as proof.
4. Read-only audit found public.handle_auth_user_updated copies auth email_confirmed_at/phone_confirmed_at into profiles and verifications. No trigger/configuration/schema was modified. Before release, implement and test explicit ownership proof, invalidation when contact changes, and server-side purchase authorization. Existing derived booleans alone must not be assumed to prove a user completed the later verification flow.
5. National ID page currently selects local images; it does not submit a KYC request. Passport has an upload/save implementation but needs real Storage/RLS/repository end-to-end verification.
6. Residence permit upload is not implemented. Bank add/manage handlers are still availability messages, not operational enrollment.
7. Backend/user-entered names, filenames, notes and rejection explanations are data and are not automatically translated.

## Suggested next implementation sequence
- Verify R6D language/UI regression results.
- Complete national ID document submission end to end, then passport, then residence permit if required for the launch population.
- Complete KYC review/resubmission and officer approval/Kao ID issuance.
- Resolve deferred contact ownership verification and server-side purchase permissions before marketplace buying is enabled.
- Real phone OTP remains a tracked blocking release test, not a passed test.
