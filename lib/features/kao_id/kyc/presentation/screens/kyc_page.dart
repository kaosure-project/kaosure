import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/application/providers/dashboard_provider.dart';
import '../../application/providers/kyc_provider.dart';
import '../widgets/identity_header.dart';
import '../widgets/page_header.dart';
import '../widgets/permission_section.dart';
import '../widgets/section_header.dart';
import '../widgets/verification_progress_card.dart';
import '../widgets/verification_section.dart';

final class KycPage
    extends ConsumerStatefulWidget {
  const KycPage({
    super.key,
  });

  @override
  ConsumerState<KycPage> createState() =>
      _KycPageState();
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
        .read(
          kycControllerProvider
              .notifier,
        )
        .load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final dashboardState = ref.watch(
      dashboardControllerProvider,
    );

    final kycState = ref.watch(
      kycControllerProvider,
    );

    final profile =
        dashboardState.profile;

    if (dashboardState.isLoading ||
        kycState.isLoading) {
      return Scaffold(
        backgroundColor:
            colorScheme.surface,
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(
        backgroundColor:
            colorScheme.surface,
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
      backgroundColor:
          colorScheme.surface,
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
                constraints:
                    BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child:
                    CustomScrollView(
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
                            const KycPageHeader(),

                            const SizedBox(
                              height: 20,
                            ),

                            IdentityHeader(
                              profile: profile,
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            VerificationProgressCard(
                              verification:
                                  kycState
                                      .verification,
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            const KycSectionHeader(
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
                                  kycState.verification,
                              identityCard:
                                  kycState.identityCard,
                              passport:
                                  kycState.passport,
                              residencePermit:
                                  kycState.residencePermit,
                              bankVerification:
                                  kycState.bankVerification,
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            const KycSectionHeader(
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