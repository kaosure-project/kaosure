import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/governance_provider.dart';
import '../../domain/entities/governance_assignment.dart';
import '../widgets/assign_governance_role_dialog.dart';
import '../widgets/governance_access_card.dart';
import '../widgets/governance_assignments_section.dart';

final class GovernancePage
    extends ConsumerStatefulWidget {
  const GovernancePage({
    super.key,
  });

  @override
  ConsumerState<GovernancePage>
      createState() =>
          _GovernancePageState();
}

final class _GovernancePageState
    extends ConsumerState<GovernancePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref
          .read(
            governanceControllerProvider
                .notifier,
          )
          .load(),
    );
  }

  Future<void> _openAssignDialog() {
    final state = ref.read(
      governanceControllerProvider,
    );

    return showDialog<void>(
      context: context,
      builder: (_) =>
          AssignGovernanceRoleDialog(
        roles: state.roles,
        onSubmit: ({
          required kaoId,
          required roleCode,
        }) {
          return ref
              .read(
                governanceControllerProvider
                    .notifier,
              )
              .assignRole(
                kaoId: kaoId,
                roleCode: roleCode,
              );
        },
      ),
    );
  }

  Future<void> _revoke(
    GovernanceAssignment assignment,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('ถอนสิทธิ์ผู้ดูแล'),
        content: Text(
          'ยืนยันถอน ' +
              assignment.roleName +
              ' จาก ' +
              assignment.kaoId +
              ' หรือไม่',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(false),
            child:
                const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(true),
            child:
                const Text('ถอนสิทธิ์'),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    await ref
        .read(
          governanceControllerProvider
              .notifier,
        )
        .revokeAssignment(
          assignment.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      governanceControllerProvider,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Kao ID Governance'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(
              governanceControllerProvider
                  .notifier,
            )
            .load(),
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                  children: [
                    Text(
                      'ศูนย์บริหาร Kao ID',
                      style: theme
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Owner และผู้ดูแลระบบใช้ Kao ID เดียวกัน โดยแยก Identity ออกจาก Role และ Permission',
                      style: theme
                          .textTheme
                          .bodyMedium,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (state.isLoading &&
                        state.access == null)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.all(
                            40,
                          ),
                          child:
                              CircularProgressIndicator(),
                        ),
                      )
                    else if (state.access ==
                        null)
                      _ErrorCard(
                        message:
                            state.errorMessage ??
                                'ไม่สามารถตรวจสอบสิทธิ์ได้',
                      )
                    else if (!state
                        .canAccess)
                      const _AccessDeniedCard()
                    else ...[
                      GovernanceAccessCard(
                        access:
                            state.access!,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (state
                              .errorMessage !=
                          null) ...[
                        _ErrorCard(
                          message: state
                              .errorMessage!,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                      if (state.access!
                          .canViewAssignments)
                        GovernanceAssignmentsSection(
                          assignments:
                              state
                                  .assignments,
                          canAssign: state
                              .access!
                              .canAssignAdmin,
                          canRevoke: state
                              .access!
                              .canRevokeAdmin,
                          onAssign:
                              _openAssignDialog,
                          onRevoke:
                              _revoke,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AccessDeniedCard
    extends StatelessWidget {
  const _AccessDeniedCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'บัญชีนี้ไม่มีสิทธิ์เข้า Governance',
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorCard
    extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colors.error,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }
}
