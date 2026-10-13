import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/kyc/presentation/pages/review/kyc_review_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../../../account/application/providers/recovery_providers.dart';
import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../governance/application/services/access_refresh.dart';
import '../../../application/providers/kyc_review_providers.dart';
import '../../../data/repositories/supabase_kyc_review_repository.dart';
import '../../../data/services/id_image_preparer.dart';
import '../../../domain/entities/thai_document_kind.dart';
import '../../../domain/reference/countries.dart';
import '../../utils/review_failure_message.dart';
import '../../widgets/thai_document_kind_label.dart';

class KycReviewDetailPage extends ConsumerStatefulWidget {
  const KycReviewDetailPage({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<KycReviewDetailPage> createState() => _KycReviewDetailPageState();
}

class _KycReviewDetailPageState extends ConsumerState<KycReviewDetailPage>
    with WidgetsBindingObserver, AccessRefresh<KycReviewDetailPage> {
  @override
  void refreshAccess() {
    ref.invalidate(kycReviewerAccessProvider);
  }

  final _reason = TextEditingController();
  final _viewed = <String>{};
  bool _busy = false, _checked = false, _recoveryChecked = false;
  Object? _failure;
  String? _owner;
  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(() {
      if (mounted) {
        refreshAccess();
      }
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _preview(String path) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final downloaded = await ref.read(kycReviewRepositoryProvider).preview(path);
      final bytes = await compute(prepareIdImage, downloaded);
      if (!mounted || ref.read(authProvider).asData?.value?.id != _owner) {
        return;
      }
      setState(() => _busy = false);
      final l = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.idViewDocument),
          content: SizedBox(
            width: 640,
            height: 420,
            child: InteractiveViewer(
              child: Consumer(
                builder: (context, ref, child) {
                  final owner = ref.watch(authProvider).asData?.value?.id;
                  final access = ref.watch(kycReviewerAccessProvider);
                  return owner == _owner &&
                          owner != null &&
                          !access.isLoading &&
                          !access.hasError &&
                          access.asData?.value == true
                      ? Image.memory(bytes, fit: BoxFit.contain)
                      : Text(l.contactSessionChanged);
                },
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l.back))],
        ),
      );
      if (mounted) {
        setState(() => _viewed.add(path));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _failure = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _decide(bool approve) async {
    if (_busy) {
      return;
    }
    final l = AppLocalizations.of(context);
    if ((!approve || widget.row['is_recovery'] == true) && _reason.text.trim().length < 3) {
      setState(() => _failure = StateError('reason'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(approve ? l.reviewApprove : l.reviewReject),
        content: Text(l.reviewConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.continueLabel)),
        ],
      ),
    );
    if (confirmed != true || !mounted || ref.read(authProvider).asData?.value?.id != _owner) {
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      if (widget.row['is_recovery'] == true) {
        await ref.read(recoveryDecisionProvider)(
          widget.row['id'] as String,
          approve,
          _reason.text.trim(),
          _recoveryChecked,
        );
      } else {
        await ref.read(kycReviewRepositoryProvider).decide(widget.row['id'] as String, approve, _reason.text.trim());
      }
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _failure = error);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentOwner = ref.watch(authProvider).asData?.value?.id;
    if (_owner == null || currentOwner != _owner) {
      return Scaffold(
        appBar: AppBar(title: Text(l.reviewTitle)),
        body: Center(child: Text(l.contactSessionChanged)),
      );
    }
    final access = ref.watch(kycReviewerAccessProvider);
    if (access.isLoading || access.hasError || access.asData?.value != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l.reviewTitle)),
        body: Center(
          child: access.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(access.hasError ? l.reviewLoadFailed : l.adminAccessDenied),
                    OutlinedButton(onPressed: refreshAccess, child: Text(l.authCheckAgain)),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
                        if (mounted) {
                          refreshAccess();
                        }
                      },
                      child: Text(l.twoFactorAuthentication),
                    ),
                  ],
                ),
        ),
      );
    }
    final row = widget.row;
    final ownVote = row['dual_review'] == true && row['first_reviewer'] == _owner;
    final paths = (row['paths'] as List? ?? []).cast<String>();
    final business = row['document_type'] == 'business_bank';
    final bank = row['document_type'] == 'bank' || business;
    final previous = (row['previous_paths'] as List? ?? []).cast<String>();
    String date(dynamic value) {
      final d = DateTime.tryParse(value?.toString() ?? '');
      return d == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(d);
    }

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.reviewTitle)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
                          if (mounted) {
                            refreshAccess();
                          }
                        },
                  child: Text(l.twoFactorAuthentication),
                ),
                if (row['dual_review'] == true) ...[
                  Text(l.dualReviewHelp),
                  if (row['first_reviewer'] != null) ...[
                    Text('${l.dualFirstDecision}: ${row['first_decision'] == true ? l.reviewApprove : l.reviewReject}'),
                    SelectableText(row['first_reason'] as String? ?? '—'),
                    Text(ownVote ? l.dualOwnVote : l.dualDisagreeHelp),
                  ],
                ],
                if (row['is_recovery'] == true) ...[
                  Text(l.recoveryReviewTitle, style: Theme.of(context).textTheme.titleLarge),
                  Text(l.recoveryReviewHelp),
                  Text('${l.idFullName}: ${row['previous_name'] ?? '—'}'),
                  SelectableText('${row['previous_number'] ?? '—'}'),
                  for (final path in previous)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _preview(path),
                      child: Text(l.recoveryPreviousEvidence),
                    ),
                  CheckboxListTile(
                    value: _recoveryChecked,
                    title: Text(l.recoveryConfirmPerson),
                    onChanged: _busy ? null : (v) => setState(() => _recoveryChecked = v ?? false),
                  ),
                  const Divider(),
                ],
                Text(reviewTypeLabel(l, row['document_type'])),
                if (ThaiDocumentKind.parse(row['thai_document_kind'] as String?) case final kind?)
                  Text('${l.thaiDocKindLabel}: ${thaiDocumentKindLabel(l, kind)}'),
                Text('${l.idFullName}: ${row['full_name'] ?? '—'}'),
                if (row['nationality'] case final String code)
                  Text(
                    '${l.nationalityLabel}: ${countryByCode(code)?.name(l.localeName.split('_').first) ?? code} ($code)',
                  )
                else if (row['issuing_country'] != null)
                  Text('${l.residenceIssuingCountry}: ${row['issuing_country']}'),
                if (row['bank_name'] != null) Text('${l.bankInstitutionName}: ${row['bank_name']}'),
                if (business) ...[
                  Text('${l.reviewOrganizationName}: ${row['organization_name'] ?? '—'}'),
                  SelectableText('${l.reviewBusinessKaoId}: ${row['business_kao_id'] ?? '—'}'),
                  Text('${l.reviewLegalName}: ${row['identity_name'] ?? l.kycUnknownStatus}'),
                  if (row['legal_name_en'] != null) Text('${l.reviewLegalNameEn}: ${row['legal_name_en']}'),
                  Text(
                    row['name_match'] == true ? l.reviewNameMatched : l.reviewNameMismatch,
                    style: TextStyle(
                      color: row['name_match'] == true ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (bank)
                  Text('${l.reviewIdentityName}: ${row['identity_name'] ?? l.kycUnknownStatus}'),
                SelectableText(
                  '${row['document_type'] == 'passport'
                      ? l.kycPassportNumber
                      : row['document_type'] == 'residence_card'
                      ? (row['thai_document_kind'] != null ? l.alienIdLabel : l.residenceNumber)
                      : bank
                      ? l.bankAccountNumber
                      : l.idNumber}: ${row['document_number'] ?? '—'}',
                ),
                if (row['address_line'] != null)
                  SelectableText(
                    '${l.piAddressTitle}: ${[row['address_line'], row['address_subdistrict'], row['address_district'], row['address_province'], row['address_postal_code']].whereType<String>().join(' ')}',
                  ),
                if (!bank) Text('${l.kycIssueDate}: ${date(row['issued_date'])}'),
                if (!bank)
                  Text(
                    '${l.kycExpiryDate}: ${row['expiry_date'] == null && (row['document_type'] == null || row['document_type'] == 'thai_national_id') ? l.idLifetime : date(row['expiry_date'])}',
                  ),
                for (final path in paths)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _preview(path),
                    child: Text(
                      path.contains('/front.')
                          ? l.idViewFront
                          : path.contains('/back.')
                          ? l.idViewBack
                          : l.idViewDocument,
                    ),
                  ),
                CheckboxListTile(
                  value: _checked,
                  title: Text(l.reviewChecked),
                  onChanged: _busy ? null : (v) => setState(() => _checked = v ?? false),
                ),
                TextField(
                  controller: _reason,
                  enabled: !_busy,
                  maxLength: 1000,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: l.reviewReason),
                ),
                if (_failure != null)
                  Text(
                    _failure is StateError && (_failure! as StateError).message == 'reason'
                        ? l.reviewReasonRequired
                        : reviewFailureMessage(l, _failure!, l.reviewActionFailed),
                  ),
                if (_busy) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      !ownVote &&
                          !_busy &&
                          _checked &&
                          (!business || row['name_match'] == true) &&
                          (row['is_recovery'] != true || (_recoveryChecked && previous.every(_viewed.contains))) &&
                          requiredEvidenceCount(row) > 0 &&
                          paths.length == requiredEvidenceCount(row) &&
                          paths.every(_viewed.contains)
                      ? () => _decide(true)
                      : null,
                  child: Text(l.reviewApprove),
                ),
                OutlinedButton(onPressed: _busy || ownVote ? null : () => _decide(false), child: Text(l.reviewReject)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
