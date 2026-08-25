import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/application/providers/dashboard_provider.dart';
import '../../application/providers/kyc_provider.dart';

import '../widgets/identity_header.dart';
import '../widgets/permission_section.dart';
import '../widgets/verification_section.dart';

final class KycPage extends ConsumerStatefulWidget {
  const KycPage({
    super.key,
  });

  @override
  ConsumerState<KycPage> createState() => _KycPageState();
}

final class _KycPageState
    extends ConsumerState<KycPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadKyc);
  }

  Future<void> _loadKyc() async {
    await ref
        .read(kycControllerProvider.notifier)
        .load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dashboardState = ref.watch(
      dashboardControllerProvider,
    );

    final kycState = ref.watch(
      kycControllerProvider,
    );

    final profile = dashboardState.profile;

    if (dashboardState.isLoading ||
        kycState.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'การยืนยันตัวตน',
          ),
        ),
        body: const Center(
          child: Text(
            'ไม่พบข้อมูลโปรไฟล์',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final isDesktop =
                width >= 1000;

            final isTablet =
                width >= 700;

            final horizontalPadding =
                isDesktop
                    ? 40.0
                    : isTablet
                        ? 28.0
                        : 16.0;

            final maxWidth =
                isDesktop
                    ? 1120.0
                    : 900.0;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: CustomScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding:
                          EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        44,
                      ),
                      sliver: SliverList(
                        delegate:
                            SliverChildListDelegate(
                          [
                            // ==================================================
                            // PAGE HEADER
                            // ==================================================

                            const _PageHeader(),

                            const SizedBox(
                              height: 20,
                            ),

                            // ==================================================
                            // IDENTITY HEADER
                            // ==================================================

                            IdentityHeader(
                              profile: profile,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            // ==================================================
                            // VERIFICATION PROGRESS
                            // ==================================================

                            _VerificationProgressCard(
                              verification:
                                  kycState
                                      .verification,
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            // ==================================================
                            // PERSONAL / IDENTITY
                            // ==================================================

                            const _SectionHeader(
                              icon: Icons
                                  .verified_user_outlined,
                              title:
                                  'ข้อมูลการยืนยันตัวตน',
                              subtitle:
                                  'จัดการข้อมูลและเอกสารที่ใช้ยืนยันตัวตนของคุณ',
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            VerificationSection(
                              verification:
                                  kycState
                                      .verification,
                              identityCard:
                                  kycState
                                      .identityCard,
                              passport:
                                  kycState.passport,
                              residencePermit:
                                  kycState
                                      .residencePermit,
                              bankVerification:
                                  kycState
                                      .bankVerification,
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            // ==================================================
                            // PERMISSIONS
                            // ==================================================

                            const _SectionHeader(
                              icon: Icons
                                  .workspace_premium_outlined,
                              title:
                                  'สิทธิ์การใช้งาน',
                              subtitle:
                                  'สิทธิ์ของคุณจะเปลี่ยนแปลงตามสถานะการยืนยันตัวตน',
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            PermissionSection(
                              verification:
                                  kycState
                                      .verification,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        // ----------------------------------------------------------------------
        // BACK BUTTON
        // ----------------------------------------------------------------------

        Material(
          color: colors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              Navigator.of(context).maybePop();
            },
            customBorder: const CircleBorder(),
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: colors.onSurface,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // ----------------------------------------------------------------------
        // TITLE
        // ----------------------------------------------------------------------

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'การยืนยันตัวตน',
                style: theme
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kao ID Identity Center',
                style: theme
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          colors.onSurfaceVariant,
                      fontWeight:
                          FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),

        // ----------------------------------------------------------------------
        // SECURITY
        // ----------------------------------------------------------------------

        if (MediaQuery.sizeOf(context).width >=
            650)
          const _SecurityBadge(),
      ],
    );
  }
}

// =============================================================================
// SECURITY BADGE
// =============================================================================

final class _SecurityBadge
    extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(
          alpha: 0.045,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 19,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'บัญชีปลอดภัย',
                style: theme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
              Text(
                'ข้อมูลได้รับการปกป้อง',
                style: theme
                    .textTheme
                    .labelSmall
                    ?.copyWith(
                      color:
                          colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

final class _SectionHeader
    extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: 0.075,
            ),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 21,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: theme
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          colors.onSurfaceVariant,
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
// VERIFICATION PROGRESS
// =============================================================================

final class _VerificationProgressCard
    extends StatelessWidget {
  const _VerificationProgressCard({
    required this.verification,
  });

  final dynamic verification;

  int _calculateProgress() {
    if (verification == null) {
      return 0;
    }

    var completed = 0;

    if (verification.emailVerified == true) {
      completed++;
    }

    if (verification.phoneVerified == true) {
      completed++;
    }

    if (_isApproved(
      verification.identityCardStatus,
    )) {
      completed++;
    }

    if (_isApproved(
      verification.passportStatus,
    )) {
      completed++;
    }

    if (_isApproved(
      verification.residencePermitStatus,
    )) {
      completed++;
    }

    if (_isApproved(
      verification.bankStatus,
    )) {
      completed++;
    }

    return ((completed / 6) * 100)
        .round()
        .clamp(0, 100);
  }

  bool _isApproved(dynamic status) {
    return status == 'approved' ||
        status == 'verified';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final progress =
        _calculateProgress();

    final value = progress / 100;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant
              .withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.025),
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
                  color: colors.primary
                      .withValues(
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
                      'ความคืบหน้าการยืนยัน',
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress >= 100
                          ? 'บัญชีของคุณได้รับการยืนยันครบถ้วนแล้ว'
                          : 'ยืนยันข้อมูลเพิ่มเติมเพื่อปลดล็อกความสามารถของบัญชี',
                      maxLines: 2,
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
              Text(
                '$progress%',
                style: theme
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                      color: colors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(999),
            child:
                LinearProgressIndicator(
              minHeight: 7,
              value: value.clamp(0, 1),
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
        ],
      ),
    );
  }
}