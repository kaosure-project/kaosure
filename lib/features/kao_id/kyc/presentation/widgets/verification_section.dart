import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/bank_verification.dart';
import '../../domain/entities/identity_card.dart';
import '../../domain/entities/passport.dart';
import '../../domain/entities/residence_permit.dart';
import '../../domain/entities/verification.dart';

import '../bank/bank_verification_page.dart';
import '../email/email_verification_page.dart';
import '../identity_card/identity_card_page.dart';
import '../passport/passport_page.dart';
import '../bank/bank_verification_tile.dart';
import '../../../phone_verification/presentation/pages/phone_verification_page.dart';
import '../screens/residence_permit_page.dart';
import '../screens/verification_history_page.dart';

final class VerificationSection
    extends StatelessWidget {
  const VerificationSection({
    super.key,
    required this.verification,
    required this.identityCard,
    required this.passport,
    required this.residencePermit,
    required this.bankVerification,
  });

  final Verification? verification;

  final IdentityCard? identityCard;

  final Passport? passport;

  final ResidencePermit? residencePermit;

  final BankVerification? bankVerification;

  @override
  Widget build(BuildContext context) {
    final user =
        Supabase.instance.client.auth.currentUser;

    final email = user?.email ?? '-';

    final emailVerified =
        user?.emailConfirmedAt != null;

    return Column(
      children: [
        // ================================================================
        // EMAIL
        // ================================================================

        _VerificationCard(
          icon: Icons.mail_outline,
          iconColor:
              const Color(0xFF22A447),
          title: 'อีเมล',
          subtitle: email,
          status: emailVerified
              ? 'ยืนยันแล้ว'
              : 'ยังไม่ยืนยัน',
          statusType: emailVerified
              ? _StatusType.success
              : _StatusType.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const EmailVerificationPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // PHONE
        // ================================================================

        _VerificationCard(
          icon: Icons.phone_outlined,
          iconColor:
              const Color(0xFFFF9800),
          title: 'เบอร์โทรศัพท์',
          subtitle: '-',
          status:
              verification?.phoneVerified ==
                      true
                  ? 'ยืนยันแล้ว'
                  : 'ยังไม่ยืนยัน',
          statusType:
              verification?.phoneVerified ==
                      true
                  ? _StatusType.success
                  : _StatusType.warning,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PhoneVerificationPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // IDENTITY CARD
        // ================================================================

        _VerificationCard(
          icon: Icons.badge_outlined,
          iconColor:
              const Color(0xFF7C4DFF),
          title: 'บัตรประชาชน',
          subtitle:
              _identitySubtitle,
          status: _statusText(
            verification
                ?.identityCardStatus,
          ),
          statusType: _statusType(
            verification
                ?.identityCardStatus,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const IdentityCardPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // PASSPORT
        // ================================================================

        _VerificationCard(
          icon:
              Icons.menu_book_outlined,
          iconColor:
              const Color(0xFF2583E8),
          title: 'หนังสือเดินทาง',
          subtitle:
              _passportSubtitle,
          status: _statusText(
            verification
                ?.passportStatus,
          ),
          statusType: _statusType(
            verification
                ?.passportStatus,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PassportPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // RESIDENCE PERMIT
        // ================================================================

        _VerificationCard(
          icon: Icons.work_outline,
          iconColor:
              const Color(0xFF00AFA3),
          title: 'ใบพำนัก',
          subtitle:
              _residenceSubtitle,
          status: _statusText(
            verification
                ?.residencePermitStatus,
          ),
          statusType: _statusType(
            verification
                ?.residencePermitStatus,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ResidencePermitPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // BANK
        // ================================================================

        BankVerificationTile(
          bankVerification:
              bankVerification,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const BankVerificationPage(),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // ================================================================
        // HISTORY
        // ================================================================

        _VerificationCard(
          icon: Icons.history,
          iconColor:
              const Color(0xFF4F72D8),
          title:
              'ประวัติการยืนยันตัวตน',
          subtitle:
              'ดูประวัติการตรวจสอบและการเปลี่ยนแปลง',
          showStatus: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const VerificationHistoryPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // SUBTITLE
  // =========================================================================

  String get _identitySubtitle {
    final status =
        verification?.identityCardStatus;

    if (!_hasDocumentStatus(status)) {
      return 'ยังไม่ได้เพิ่ม';
    }

    final expiry =
        identityCard?.expiryDate;

    if (expiry == null) {
      return 'ยืนยันข้อมูลแล้ว';
    }

    return 'หมดอายุ ${_formatDate(expiry)}';
  }

  String get _passportSubtitle {
    final status =
        verification?.passportStatus;

    if (!_hasDocumentStatus(status)) {
      return 'ยังไม่ได้ระบุวันหมดอายุ';
    }

    final expiry =
        passport?.expiryDate;

    if (expiry == null) {
      return 'ยังไม่ได้ระบุวันหมดอายุ';
    }

    return 'หมดอายุ ${_formatDate(expiry)}';
  }

  String get _residenceSubtitle {
    final status =
        verification?.residencePermitStatus;

    if (!_hasDocumentStatus(status)) {
      return 'ยังไม่ได้เพิ่ม';
    }

    final expiry =
        residencePermit?.expiryDate;

    if (expiry == null) {
      return 'ยืนยันข้อมูลแล้ว';
    }

    return 'หมดอายุ ${_formatDate(expiry)}';
  }

  // =========================================================================
  // STATUS
  // =========================================================================

  bool _hasDocumentStatus(
    String? status,
  ) {
    if (status == null) {
      return false;
    }

    switch (status) {
      case 'verified':
      case 'approved':
      case 'completed':
      case 'complete':
      case 'pending':
      case 'submitted':
      case 'reviewing':
      case 'rejected':
      case 'expired':
        return true;

      default:
        return false;
    }
  }

  String _statusText(
    String? status,
  ) {
    switch (status) {
      case 'verified':
      case 'approved':
      case 'completed':
      case 'complete':
        return 'ยืนยันแล้ว';

      case 'pending':
      case 'submitted':
      case 'reviewing':
        return 'กำลังตรวจสอบ';

      case 'rejected':
        return 'ไม่ผ่าน';

      case 'expired':
        return 'หมดอายุ';

      case 'not_started':
      default:
        return 'ยังไม่ได้เพิ่ม';
    }
  }

  _StatusType _statusType(
    String? status,
  ) {
    switch (status) {
      case 'verified':
      case 'approved':
      case 'completed':
      case 'complete':
        return _StatusType.success;

      case 'pending':
      case 'submitted':
      case 'reviewing':
      case 'rejected':
      case 'expired':
        return _StatusType.warning;

      case 'not_started':
      default:
        return _StatusType.neutral;
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// =============================================================================
// STATUS TYPE
// =============================================================================

enum _StatusType {
  success,
  warning,
  neutral,
}

// =============================================================================
// VERIFICATION CARD
// =============================================================================

final class _VerificationCard
    extends StatelessWidget {
  const _VerificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
    this.statusType =
        _StatusType.neutral,
    this.showStatus = true,
  });

  final IconData icon;

  final Color iconColor;

  final String title;

  final String subtitle;

  final String? status;

  final _StatusType statusType;

  final VoidCallback onTap;

  final bool showStatus;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Ink(
          height: 82,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          decoration:
              BoxDecoration(
            color: colors.surface,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: colors
                  .outlineVariant
                  .withValues(
                alpha: 0.70,
              ),
            ),
          ),
          child: Row(
            children: [
              // ============================================================
              // ICON
              // ============================================================

              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color:
                      iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: iconColor,
                ),
              ),

              const SizedBox(width: 15),

              // ============================================================
              // TITLE / SUBTITLE
              // ============================================================

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                        color:
                            colors.onSurface,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
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

              const SizedBox(width: 12),

              // ============================================================
              // STATUS
              // ============================================================

              if (showStatus &&
                  status != null)
                _StatusBadge(
                  text: status!,
                  type: statusType,
                ),

              const SizedBox(width: 8),

              // ============================================================
              // CHEVRON
              // ============================================================

              Icon(
                Icons
                    .chevron_right_rounded,
                size: 24,
                color: colors
                    .onSurfaceVariant,
              ),
            ],
          ),
        ),
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
    required this.text,
    required this.type,
  });

  final String text;

  final _StatusType type;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final Color color;

    final IconData icon;

    switch (type) {
      case _StatusType.success:
        color =
            const Color(0xFF2EAD58);
        icon =
            Icons.check_circle_rounded;
        break;

      case _StatusType.warning:
        color =
            const Color(0xFFFF9800);
        icon = Icons.error_rounded;
        break;

      case _StatusType.neutral:
        color =
            colors.onSurfaceVariant;
        icon = Icons
            .remove_circle_outline;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          999,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(
              color: color,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
          Icon(
            icon,
            size: 14,
            color: color,
          ),
        ],
      ),
    );
  }
}