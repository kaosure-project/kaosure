# R9A — Owner member lookup

Requires existing R8L languages and R8M. Includes original routes from R3 with /admin/members added and R6A home with an Owner entry. Preserve your backup before extraction.

Backend migration owner_member_read_r9a is already installed; database/member_read_r9a.sql is retained as source, do not rerun manually.

Owner-only exact email/account UUID/Kao ID lookup, minimum member summary. Contact verification reads Auth timestamps, KYC and Kao ID remain distinct. Reads are logged to existing activity_logs (query text is not logged). No member modification, staff assignment or KYC approval in this batch.

SQL checks passed: Owner allowed and correct match; absent account returns null; non-owner denied. Test queries rolled back their read-audit records. Security advisor checked; pre-existing project hardening findings remain outside this patch. No R9A-specific advisor finding identified.

Flutter is unavailable here. Run flutter gen-l10n, flutter analyze, flutter test test/localization/member_admin_r9a_test.dart, then flutter test test/localization.

Sign in as the configured Owner. Home -> Member administration. Alternatively http://localhost:7357/#/admin/members . Search the full email or ID. Ordinary members must be denied even with the direct URL. User data is hidden on logout/account change. Backend checks permission again on every search.

All seven languages included; new translations have not received native-speaker review. This patch does not close R8M runtime acceptance, SMS, staff assignment, multi-document review, expiry/renewal or production hardening.
