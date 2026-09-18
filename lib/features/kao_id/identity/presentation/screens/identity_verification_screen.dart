import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/verification_status.dart';

import '../providers/identity_controller_provider.dart';
import '../widgets/document_tile.dart';
import '../widgets/upload_document_button.dart';
import '../widgets/verification_status_card.dart';

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

    Future.microtask(() {
      ref
          .read(identityControllerProvider.notifier)
          .loadDocuments(
            
          );
    });
  }

  Future<void> _refresh() {
    return ref
        .read(identityControllerProvider.notifier)
        .refresh(
          
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันตัวตน'),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Text(state.errorMessage!),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                VerificationStatusCard(
                  status: state.documents.isEmpty
                      ? VerificationStatus.notSubmitted
                      : state.documents.first.verification?.status ??
                          VerificationStatus.notSubmitted,
                ),

                const SizedBox(height: 24),

                const Text(
                  'เอกสารของคุณ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                if (state.documents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'ยังไม่มีเอกสาร',
                      ),
                    ),
                  )
                else
                  ...state.documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DocumentTile(
                        document: document,
                        onTap: () {
                          // TODO:
                          // เปิดหน้ารายละเอียดเอกสาร
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                UploadDocumentButton(
                  onPressed: () {
                    // TODO:
                    // เปิดหน้าอัปโหลดเอกสาร
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}