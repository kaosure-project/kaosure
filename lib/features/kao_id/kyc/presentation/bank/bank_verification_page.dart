import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/kyc_provider.dart';
import '../../domain/entities/bank_verification.dart';

final class BankVerificationPage
    extends ConsumerStatefulWidget {
  const BankVerificationPage({
    super.key,
  });

  @override
  ConsumerState<BankVerificationPage>
      createState() =>
          _BankVerificationPageState();
}

final class _BankVerificationPageState
    extends ConsumerState<BankVerificationPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_load);
  }

  Future<void> _load() async {
    await ref
        .read(kycControllerProvider.notifier)
        .load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state =
        ref.watch(kycControllerProvider);

    final bank =
        state.bankVerification;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        title: const Text(
          'บัญชีธนาคาร',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              40,
            ),
            children: [
              _PageHeader(
                bank: bank,
              ),

              const SizedBox(height: 24),

              if (state.isLoading)
                const _LoadingCard(),

              if (!state.isLoading &&
                  state.hasError)
                _ErrorCard(
                  message:
                      state.errorMessage!,
                  onRetry: _load,
                ),

              if (!state.isLoading &&
                  !state.hasError &&
                  bank == null)
                _EmptyBankCard(
                  onAdd: _onAddBank,
                ),

              if (!state.isLoading &&
                  !state.hasError &&
                  bank != null) ...[
                _BankAccountCard(
                  bank: bank,
                ),

                const SizedBox(height: 16),

                _VerificationStatusCard(
                  bank: bank,
                ),

                const SizedBox(height: 16),

                _KycNameMatchCard(
                  bank: bank,
                ),

                if (bank.rejectedReason != null &&
                    bank.rejectedReason!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _RejectedReasonCard(
                    reason:
                        bank.rejectedReason!,
                  ),
                ],

                const SizedBox(height: 16),

                _SecurityCard(
                  bank: bank,
                ),

                if (!bank.isTrusted) ...[
                  const SizedBox(height: 20),
                  _ActionButton(
                    bank: bank,
                    onPressed: _onManageBank,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onAddBank() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'ขั้นตอนเพิ่มบัญชีธนาคารจะเปิดในขั้นตอนถัดไป',
          ),
        ),
      );
  }

  void _onManageBank() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'การจัดการบัญชีธนาคารจะเปิดในขั้นตอนถัดไป',
          ),
        ),
      );
  }
}

// =============================================================================
// PAGE HEADER
// =============================================================================

final class _PageHeader
    extends StatelessWidget {
  const _PageHeader({
    required this.bank,
  });

  final BankVerification? bank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer,
            colors.surfaceContainerHighest,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              colors.outlineVariant
                  .withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.surface
                  .withValues(alpha: 0.75),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              size: 30,
              color: colors.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ยืนยันบัญชีธนาคาร',
                  style: theme
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 6),

                Text(
                  bank == null
                      ? 'เพิ่มบัญชีธนาคารเพื่อใช้ในการรับเงินและบริการทางการเงินของ Kao Ecosystem'
                      : 'ตรวจสอบสถานะบัญชีและความสอดคล้องกับข้อมูล KYC',
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: colors
                            .onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// LOADING
// =============================================================================

final class _LoadingCard
    extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 42,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              colors.outlineVariant,
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text(
            'กำลังตรวจสอบข้อมูลบัญชีธนาคาร...',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ERROR
// =============================================================================

final class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.error
              .withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ไม่สามารถโหลดข้อมูลได้',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                        color:
                            colors.onErrorContainer,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            message,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
                  color:
                      colors.onErrorContainer,
                  height: 1.4,
                ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY
// =============================================================================

final class _EmptyBankCard
    extends StatelessWidget {
  const _EmptyBankCard({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 38,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'ยังไม่มีบัญชีธนาคาร',
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'เพิ่มบัญชีธนาคารเพื่อเข้าสู่กระบวนการตรวจสอบและยืนยันตัวตนทางการเงิน',
            textAlign:
                TextAlign.center,
            style: theme
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: colors
                      .onSurfaceVariant,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(
                Icons.add_card_rounded,
              ),
              label: const Text(
                'เพิ่มบัญชีธนาคาร',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BANK ACCOUNT
// =============================================================================

final class _BankAccountCard
    extends StatelessWidget {
  const _BankAccountCard({
    required this.bank,
  });

  final BankVerification bank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              colors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.025),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BankIcon(
                bankName:
                    bank.bankName,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.bankName,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'บัญชีธนาคาร',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colors
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              if (bank.isPrimary == true)
                _PrimaryBadge(),
            ],
          ),

          const SizedBox(height: 24),

          _AccountNumberDisplay(
            accountNumber:
                bank.accountNumber,
          ),

          const SizedBox(height: 22),

          const Divider(),

          const SizedBox(height: 18),

          _InfoItem(
            icon:
                Icons.person_outline_rounded,
            label: 'ชื่อเจ้าของบัญชี',
            value:
                bank.accountName,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BANK ICON
// =============================================================================

final class _BankIcon
    extends StatelessWidget {
  const _BankIcon({
    required this.bankName,
  });

  final String bankName;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.account_balance_rounded,
        color:
            colors.onPrimaryContainer,
        size: 28,
      ),
    );
  }
}

// =============================================================================
// PRIMARY BADGE
// =============================================================================

final class _PrimaryBadge
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.primary
            .withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 15,
            color: colors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'บัญชีหลัก',
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACCOUNT NUMBER
// =============================================================================

final class _AccountNumberDisplay
    extends StatelessWidget {
  const _AccountNumberDisplay({
    required this.accountNumber,
  });

  final String accountNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card_outlined,
            color:
                colors.onSurfaceVariant,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'เลขบัญชี',
                  style: theme
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color: colors
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _maskAccountNumber(
                    accountNumber,
                  ),
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing:
                            1.2,
                      ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.lock_outline_rounded,
            size: 19,
            color:
                colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VERIFICATION STATUS
// =============================================================================

final class _VerificationStatusCard
    extends StatelessWidget {
  const _VerificationStatusCard({
    required this.bank,
  });

  final BankVerification bank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final config =
        _statusConfig(
      theme,
      bank.status,
    );

    return _SectionCard(
      title: 'สถานะการยืนยัน',
      icon:
          Icons.verified_outlined,
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: config.foreground
                    .withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config.icon,
                color:
                    config.foreground,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: theme
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          color:
                              config.foreground,
                          fontWeight:
                              FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    config.description,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color:
                              config.foreground,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// KYC NAME MATCH
// =============================================================================

final class _KycNameMatchCard
    extends StatelessWidget {
  const _KycNameMatchCard({
    required this.bank,
  });

  final BankVerification bank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final config =
        _nameMatchConfig(
      theme,
      bank.nameMatchStatus,
    );

    return _SectionCard(
      title:
          'ตรวจสอบชื่อกับ KYC',
      icon:
          Icons.person_search_outlined,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: config.foreground
                    .withValues(
                  alpha: 0.12,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  config.icon,
                  color:
                      config.foreground,
                  size: 24,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.title,
                        style: theme
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              color:
                                  config.foreground,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        config.description,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  config.foreground,
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (bank.nameMatchReason != null &&
              bank.nameMatchReason!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReasonRow(
              reason:
                  bank.nameMatchReason!,
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// REJECTED REASON
// =============================================================================

final class _RejectedReasonCard
    extends StatelessWidget {
  const _RejectedReasonCard({
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.errorContainer
            .withValues(alpha: 0.65),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colors.error
              .withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'เหตุผลที่ไม่ผ่าน',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: TextStyle(
                    color:
                        colors.onErrorContainer,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECURITY
// =============================================================================

final class _SecurityCard
    extends StatelessWidget {
  const _SecurityCard({
    required this.bank,
  });

  final BankVerification bank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final trusted =
        bank.isTrusted;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: trusted
            ? colors.primaryContainer
                .withValues(alpha: 0.55)
            : colors.surfaceContainerHighest
                .withValues(alpha: 0.65),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: trusted
              ? colors.primary.withValues(
                  alpha: 0.16,
                )
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: trusted
                  ? colors.primary
                      .withValues(
                      alpha: 0.10,
                    )
                  : colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              trusted
                  ? Icons.shield_rounded
                  : Icons.security_outlined,
              color: trusted
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  trusted
                      ? 'บัญชีธนาคารที่เชื่อถือได้'
                      : 'การรักษาความปลอดภัย',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                ),

                const SizedBox(height: 5),

                Text(
                  trusted
                      ? 'บัญชีผ่านการยืนยันและชื่อบัญชีตรงกับข้อมูลที่ผ่าน KYC แล้ว'
                      : 'ชื่อบัญชีธนาคารต้องตรงกับข้อมูลที่ผ่าน KYC ก่อนจึงจะถือว่าเป็นบัญชีที่เชื่อถือได้',
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: colors
                            .onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACTION
// =============================================================================

final class _ActionButton
    extends StatelessWidget {
  const _ActionButton({
    required this.bank,
    required this.onPressed,
  });

  final BankVerification bank;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
  

    final label =
        bank.isRejected
            ? 'ตรวจสอบข้อมูลอีกครั้ง'
            : 'จัดการบัญชีธนาคาร';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(
          bank.isRejected
              ? Icons.refresh_rounded
              : Icons.account_balance_outlined,
        ),
        label: Text(label),
      ),
    );
  }
}

// =============================================================================
// SECTION CARD
// =============================================================================

final class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: colors.primary,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// =============================================================================
// INFO ITEM
// =============================================================================

final class _InfoItem
    extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color:
              colors.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color: colors
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// REASON
// =============================================================================

final class _ReasonRow
    extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notes_rounded,
          size: 19,
          color:
              colors.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            reason,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: colors
                      .onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STATUS CONFIGURATION
// =============================================================================

_StatusConfig _statusConfig(
  ThemeData theme,
  String status,
) {
  final colors = theme.colorScheme;

  switch (status) {
    case 'approved':
      return _StatusConfig(
        title: 'ยืนยันแล้ว',
        description:
            'บัญชีธนาคารผ่านการตรวจสอบแล้ว',
        icon:
            Icons.check_circle_rounded,
        foreground:
            Colors.green.shade700,
        background:
            Colors.green.withValues(
          alpha: 0.08,
        ),
      );

    case 'pending':
      return _StatusConfig(
        title: 'กำลังตรวจสอบ',
        description:
            'ระบบกำลังตรวจสอบข้อมูลบัญชีธนาคาร',
        icon:
            Icons.hourglass_top_rounded,
        foreground:
            colors.tertiary,
        background:
            colors.tertiary.withValues(
          alpha: 0.08,
        ),
      );

    case 'manual_review':
      return _StatusConfig(
        title:
            'อยู่ระหว่างการตรวจสอบเพิ่มเติม',
        description:
            'ข้อมูลต้องได้รับการตรวจสอบเพิ่มเติม',
        icon:
            Icons.manage_search_rounded,
        foreground:
            colors.tertiary,
        background:
            colors.tertiary.withValues(
          alpha: 0.08,
        ),
      );

    case 'rejected':
      return _StatusConfig(
        title: 'ไม่ผ่านการยืนยัน',
        description:
            'บัญชีธนาคารไม่ผ่านกระบวนการตรวจสอบ',
        icon:
            Icons.cancel_rounded,
        foreground:
            colors.error,
        background:
            colors.error.withValues(
          alpha: 0.08,
        ),
      );

    case 'expired':
      return _StatusConfig(
        title: 'หมดอายุ',
        description:
            'ข้อมูลการยืนยันบัญชีหมดอายุ',
        icon:
            Icons.event_busy_rounded,
        foreground:
            colors.error,
        background:
            colors.error.withValues(
          alpha: 0.08,
        ),
      );

    case 'not_started':
    default:
      return _StatusConfig(
        title:
            'ยังไม่ได้เริ่มการยืนยัน',
        description:
            'บัญชีธนาคารยังไม่ได้เข้าสู่กระบวนการตรวจสอบ',
        icon:
            Icons.info_outline_rounded,
        foreground:
            colors.onSurfaceVariant,
        background:
            colors.surfaceContainerHighest,
      );
  }
}

// =============================================================================
// NAME MATCH CONFIGURATION
// =============================================================================

_NameMatchConfig _nameMatchConfig(
  ThemeData theme,
  String? status,
) {
  final colors = theme.colorScheme;

  switch (status) {
    case 'matched':
      return _NameMatchConfig(
        title:
            'ชื่อบัญชีตรงกับข้อมูล KYC',
        description:
            'ชื่อเจ้าของบัญชีผ่านการตรวจสอบและตรงกับข้อมูลที่ยืนยันตัวตนไว้',
        icon:
            Icons.verified_rounded,
        foreground:
            Colors.green.shade700,
        background:
            Colors.green.withValues(
          alpha: 0.08,
        ),
      );

    case 'mismatched':
      return _NameMatchConfig(
        title:
            'ชื่อบัญชีไม่ตรงกับข้อมูล KYC',
        description:
            'ระบบพบความแตกต่างระหว่างชื่อบัญชีธนาคารกับข้อมูล KYC',
        icon:
            Icons.warning_amber_rounded,
        foreground:
            colors.error,
        background:
            colors.error.withValues(
          alpha: 0.08,
        ),
      );

    case 'manual_review':
      return _NameMatchConfig(
        title:
            'กำลังตรวจสอบชื่อบัญชี',
        description:
            'ระบบต้องตรวจสอบข้อมูลเพิ่มเติมก่อนสรุปผล',
        icon:
            Icons.manage_search_rounded,
        foreground:
            colors.tertiary,
        background:
            colors.tertiary.withValues(
          alpha: 0.08,
        ),
      );

    case 'pending':
    default:
      return _NameMatchConfig(
        title:
            'รอการตรวจสอบชื่อบัญชี',
        description:
            'ชื่อบัญชีจะถูกตรวจสอบกับข้อมูล KYC',
        icon:
            Icons.hourglass_empty_rounded,
        foreground:
            colors.onSurfaceVariant,
        background:
            colors.surfaceContainerHighest,
      );
  }
}

// =============================================================================
// MASK ACCOUNT NUMBER
// =============================================================================

String _maskAccountNumber(
  String accountNumber,
) {
  final value =
      accountNumber.trim();

  if (value.length <= 4) {
    return value;
  }

  final visible =
      value.substring(
    value.length - 4,
  );

  return '•••• •••• $visible';
}

// =============================================================================
// CONFIGURATION MODELS
// =============================================================================

final class _StatusConfig {
  const _StatusConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color foreground;
  final Color background;
}

final class _NameMatchConfig {
  const _NameMatchConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color foreground;
  final Color background;
}