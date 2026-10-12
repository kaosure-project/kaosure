import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../../app/routes/kao_id_routes.dart';
import '../../../../../shared/design_system/colors/app_colors.dart';
import '../../../dashboard/presentation/widgets/kao_id_scaffold.dart';
import '../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../application/controllers/reveal_controller.dart';
import '../../application/providers/personal_info_providers.dart';
import '../../domain/entities/personal_info.dart';
import '../../domain/entities/sensitive_field.dart';
import '../widgets/general_info_section.dart';
import '../widgets/id_address_card.dart';
import '../widgets/identity_document_section.dart';
import '../widgets/password_prompt_dialog.dart';

class PersonalInfoPage extends ConsumerWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(personalInfoProvider);
    return KaoIdScaffold(
      selectedIndex: 1,
      onSelected: (index) =>
          Navigator.of(context).pushReplacementNamed(KaoIdRoutes.accountTabs[index]),
      child: info.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(l10n.piLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => ref.invalidate(personalInfoProvider), child: Text(l10n.retry)),
          ]),
        )),
        data: (value) => PersonalInfoContent(
          info: value,
          onRefresh: () => ref.refresh(personalInfoProvider.future),
        ),
      ),
    );
  }
}

/// Page body; also used directly by previews and tests.
class PersonalInfoContent extends ConsumerWidget {
  const PersonalInfoContent({super.key, required this.info, this.onRefresh});

  final PersonalInfo info;
  final Future<void> Function()? onRefresh;

  Future<void> _reveal(BuildContext context, WidgetRef ref, SensitiveField field) async {
    final controller = ref.read(revealControllerProvider.notifier);
    if (controller.needsPassword) {
      final unlocked = await showRevealPasswordDialog(context, unlock: controller.unlock);
      if (!unlocked) return;
    }
    await controller.reveal(field);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reveal = ref.watch(revealControllerProvider);
    ref.listen<RevealState>(revealControllerProvider, (previous, next) {
      final code = next.error;
      if (code == null || code == previous?.error || next.loading.isNotEmpty) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(switch (code) {
          'password' => l10n.piPasswordWrong,
          'rate_limited' => l10n.piRateLimited,
          'session' => l10n.contactSessionChanged,
          _ => l10n.piRevealFailed,
        })));
    });
    void onReveal(SensitiveField field) => _reveal(context, ref, field);
    void onHide(SensitiveField field) => ref.read(revealControllerProvider.notifier).hide(field);
    void openKyc() => Navigator.of(context).pushNamed(KaoIdRoutes.kyc);

    return SectionBody(
      icon: Icons.contact_page_outlined,
      color: AppColors.kaoBlue,
      tint: AppColors.kaoBlueSoft,
      title: l10n.personalDetailsTitle,
      description: l10n.piPageDescription,
      onRefresh: onRefresh,
      start: [
        GeneralInfoSection(info: info, reveal: reveal, onReveal: onReveal, onHide: onHide),
        const _PrivacyNote(),
      ],
      end: [
        IdentityDocumentSection(document: info.document, reveal: reveal,
          onReveal: onReveal, onHide: onHide, onVerify: openKyc),
        IdAddressCard(address: info.address, onVerify: openKyc),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.kaoGreenSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.shield_outlined, color: AppColors.kaoGreen),
          const SizedBox(width: 12),
          Expanded(child: Text(AppLocalizations.of(context).piPrivacyNote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary))),
        ]),
      );
}
