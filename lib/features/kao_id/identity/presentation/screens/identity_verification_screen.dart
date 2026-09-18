import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/document_status.dart';
import '../providers/identity_controller_provider.dart';
import '../widgets/document_tile.dart';

final class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

final class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(identityControllerProvider.notifier).loadDocuments(),
    );
  }

  Future<void> _refresh() {
    return ref.read(identityControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เอกสารยืนยันตัวตน'),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }

          final pendingCount = state.documents
              .where((document) => document.status == DocumentStatus.pendingReview)
              .length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DocumentSummaryCard(
                  documentCount: state.documents.length,
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 24),
                Text(
                  'เอกสารของคุณ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                if (state.documents.isEmpty)
                  const _EmptyDocumentsCard()
                else
                  ...state.documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DocumentTile(document: document),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'การส่งเอกสารเข้าตรวจสอบและสถานะ KYC จัดการโดยโมดูล KYC '
                  'เพื่อให้เอกสารและกระบวนการตรวจสอบมีเจ้าของข้อมูลแยกจากกันอย่างชัดเจน',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _DocumentSummaryCard extends StatelessWidget {
  const _DocumentSummaryCard({
    required this.documentCount,
    required this.pendingCount,
  });

  final int documentCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identity Documents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$documentCount เอกสาร · $pendingCount รายการกำลังตรวจสอบ',
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

final class _EmptyDocumentsCard extends StatelessWidget {
  const _EmptyDocumentsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.upload_file_outlined),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ยังไม่มีเอกสารยืนยันตัวตน กรุณาเพิ่มเอกสารผ่านขั้นตอน KYC',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
