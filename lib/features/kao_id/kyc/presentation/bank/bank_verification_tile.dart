import 'package:flutter/material.dart';

import '../../domain/entities/bank_verification.dart';

final class BankVerificationTile
    extends StatelessWidget {
  const BankVerificationTile({
    super.key,
    required this.bankVerification,
    required this.onTap,
  });

  final BankVerification? bankVerification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bank = bankVerification;

    if (bank == null) {
      return _EmptyTile(
        onTap: onTap,
      );
    }

    final status =
        _statusConfig(
      context,
      bank.status,
    );

    final nameMatch =
        _nameMatchConfig(
      context,
      bank.nameMatchStatus,
    );

    return Material(
      color: colors.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Ink(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              _BankIcon(
                trusted: bank.isTrusted,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.bankName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _maskAccountNumber(
                        bank.accountNumber,
                      ),
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: colors
                                .onSurfaceVariant,
                            letterSpacing:
                                0.6,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusBadge(
                          label:
                              status.label,
                          color:
                              status.color,
                        ),
                        _StatusBadge(
                          label:
                              nameMatch.label,
                          color:
                              nameMatch.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY TILE
// =============================================================================

final class _EmptyTile
    extends StatelessWidget {
  const _EmptyTile({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Ink(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons
                      .account_balance_outlined,
                  color:
                      colors.primary,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บัญชีธนาคาร',
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ยังไม่ได้เพิ่มบัญชีธนาคาร',
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

              Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
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
    required this.trusted,
  });

  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: trusted
            ? colors.primary
                .withValues(alpha: 0.10)
            : colors
                .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Icon(
        trusted
            ? Icons.verified_rounded
            : Icons
                .account_balance_outlined,
        color: trusted
            ? colors.primary
            : colors.onSurfaceVariant,
        size: 26,
      ),
    );
  }
}

// =============================================================================
// STATUS BADGE
// =============================================================================

final class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.09),
        borderRadius:
            BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// VERIFICATION STATUS
// =============================================================================

_StatusConfig _statusConfig(
  BuildContext context,
  String status,
) {
  final colors =
      Theme.of(context).colorScheme;

  switch (status) {
    case 'approved':
      return _StatusConfig(
        label: 'ยืนยันแล้ว',
        color: Colors.green.shade700,
      );

    case 'pending':
      return _StatusConfig(
        label: 'กำลังตรวจสอบ',
        color: colors.tertiary,
      );

    case 'rejected':
      return _StatusConfig(
        label: 'ไม่ผ่าน',
        color: colors.error,
      );

    case 'manual_review':
      return _StatusConfig(
        label: 'ตรวจสอบเพิ่มเติม',
        color: colors.tertiary,
      );

    case 'expired':
      return _StatusConfig(
        label: 'หมดอายุ',
        color: colors.error,
      );

    case 'not_started':
    default:
      return _StatusConfig(
        label: 'ยังไม่ได้ยืนยัน',
        color: colors.onSurfaceVariant,
      );
  }
}

// =============================================================================
// KYC NAME MATCH
// =============================================================================

_StatusConfig _nameMatchConfig(
  BuildContext context,
  String? status,
) {
  final colors =
      Theme.of(context).colorScheme;

  switch (status) {
    case 'matched':
      return _StatusConfig(
        label: 'ชื่อ KYC ตรงกัน',
        color: Colors.green.shade700,
      );

    case 'mismatched':
      return _StatusConfig(
        label: 'ชื่อไม่ตรง',
        color: colors.error,
      );

    case 'manual_review':
      return _StatusConfig(
        label: 'ตรวจชื่อเพิ่มเติม',
        color: colors.tertiary,
      );

    case 'pending':
    default:
      return _StatusConfig(
        label: 'รอตรวจชื่อ KYC',
        color: colors.onSurfaceVariant,
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
// CONFIG
// =============================================================================

final class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}