import 'package:flutter/material.dart';

import '../../domain/entities/verification.dart';

final class VerificationProgressCard extends StatelessWidget {
  const VerificationProgressCard({
    required this.verification,
    super.key,
  });

  final Verification? verification;

  int _calculateKycProgress() {
    final current = verification;

    if (current == null) {
      return 0;
    }

    var completed = 0;
    const total = 5;

    if (current.emailVerified) {
      completed++;
    }

    if (current.phoneVerified) {
      completed++;
    }

    if (_isApproved(
      current.identityCardStatus,
    )) {
      completed++;
    }

    if (_isApproved(
      current.passportStatus,
    )) {
      completed++;
    }

    if (_isApproved(
      current.residencePermitStatus,
    )) {
      completed++;
    }

    return ((completed / total) * 100)
        .round()
        .clamp(0, 100);
  }

  bool _isApproved(String status) {
    return status == 'approved' ||
        status == 'verified';
  }

  bool _isBankVerified() {
    final current = verification;

    if (current == null) {
      return false;
    }

    return _isApproved(
      current.bankStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final kycProgress = _calculateKycProgress();
    final kycValue = kycProgress / 100;
    final bankVerified = _isBankVerified();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(
            alpha: 0.75,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ความคืบหน้าการยืนยันตัวตน',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kycProgress >= 100
                          ? 'การยืนยันตัวตนของคุณครบถ้วนแล้ว'
                          : 'ยืนยันข้อมูลเพิ่มเติมเพื่อยืนยันตัวตนของคุณ',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                            colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$kycProgress%',
                style: theme.textTheme.titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: kycValue.clamp(0, 1),
              backgroundColor:
                  colors.primary.withValues(
                alpha: 0.09,
              ),
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 14),

          _VerificationStatusRow(
            icon: Icons.badge_outlined,
            title: 'Identity / KYC',
            status: kycProgress >= 100
                ? 'ยืนยันครบแล้ว'
                : 'กำลังดำเนินการ',
            isVerified: kycProgress >= 100,
          ),

          const SizedBox(height: 10),

          _VerificationStatusRow(
            icon: Icons.account_balance_outlined,
            title: 'บัญชีธนาคาร',
            status: bankVerified
                ? 'ยืนยันแล้ว'
                : 'ยังไม่ได้ยืนยัน',
            isVerified: bankVerified,
          ),
        ],
      ),
    );
  }
}

final class _VerificationStatusRow
    extends StatelessWidget {
  const _VerificationStatusRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.isVerified,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final statusColor = isVerified
        ? colors.primary
        : colors.onSurfaceVariant;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: statusColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          status,
          style: theme.textTheme.bodySmall
              ?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}