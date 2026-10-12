# Kao ID — R5 / KYC sections

## Evidence and scope
Base: uploaded 20260921 snapshot + R2/R3 + installed R4.
User verified analyze and 69 localization tests before this patch.
Reference: https://id.yahoo.co.jp/about/check_settings.html
Adopt grouped account settings and clear detail pages, not Yahoo branding or its authentication rules.

## Completed in source (not yet Flutter-tested)
- KYC hub: contact verification / documents / latest request / history.
- All labels on the new hub and history page in Thai and English.
- Existing email/phone/identity card/passport/residence/bank destination pages retained.
- Residence and bank under Additional details; residence explicitly says upload unavailable.
- Five KYC loads isolated. Failed optional resource no longer discards successful resources.
- Null request/bank results clear stale records. Unknown data not presented as verified.
- Clear/logout invalidates pending controller responses.
- Submission blocked until verification, request and document reads are available.
- History distinguishes failed fetch from empty history; retry and localized dates.
- Bank page depends on its own resource result instead of an unrelated history failure.
- Removed service permission teaser/score from this hub; underlying files retained for review.
  Existing permission widget unconditionally enables purchases and advertises unfinished services;
  it is not a server authorization decision and should not be used as one.

## Confirmed backend blocker (metadata only, no personal rows read)
2026-09-22, project dyfpzmhalfmykvxjdcoq:
All five tables have RLS enabled and owner SELECT policies, but authenticated has
neither table SELECT nor any column SELECT privileges (0/19 bank, 0/22 documents,
0/8 logs, 0/11 requests, 0/19 verifications).
Therefore current direct client reads lack permission. UI changes alone cannot restore them.
SQL proposal: kyc_read_access_R5_REVIEW.sql. Transaction ends ROLLBACK by default.
Only SELECT to authenticated; ownership RLS preserved; no data mutation or write grants.
Not applied. Must approve and verify with two actual accounts before closing backend task.

## Next batches in order
1. Read access repair, actual account KYC load and cross-account isolation.
2. Email + phone detail pages: bilingual text, actual confirmation/OTP, resend/cooldown/errors.
3. Identity card + passport: validation, upload, submit, rejected/resubmit, private document access.
4. KYC officer review and Kao ID issuance: uniqueness and server-side transition checks.
5. Device/session security and missing account/privacy functions.
6. Service enrollment for secondhand after Kao ID acceptance.
Bank account add/manage and residence upload remain incomplete; not claimed finished.
Child-page language coverage is still a separate queue; this patch does not translate all KYC forms.

## Tests added (not executed here)
- Partial history failure preserves verification; retry clears failure.
- Unknown request blocks submission; successful null read clears old request.
- Clear prevents late response repopulating account state.
- Thai/English menus remain reachable when every read fails, at 320px / 2x text.
- History failure is not empty history; retry recovers to genuine empty result.
Existing 69 tests should continue to run. No existing test overwritten.
