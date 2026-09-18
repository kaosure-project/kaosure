import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessReviewPage extends StatelessWidget {
  const BusinessReviewPage({
    super.key,
    required this.businessInformation,
    this.onSubmit,
  });

  static const routeName =
      '/kao-id/business/review';

  final Map<String, dynamic> businessInformation;

  /// Callback สำหรับส่งคำขอ Business Registration
  ///
  /// Application layer เป็นผู้รับผิดชอบ
  /// การ upload และการเรียก UseCase จริง
  final Future<void> Function(
    Map<String, dynamic> businessInformation,
  )? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final document =
        businessInformation['registration_document']
            as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูล'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ตรวจสอบข้อมูลกิจการ',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณาตรวจสอบข้อมูลทั้งหมด '
                'ก่อนส่งคำขอตรวจสอบกิจการ',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _SectionCard(
                title: 'ข้อมูลกิจการ',
                icon: Icons.business_outlined,
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'ชื่อกิจการ',
                      value: _value(
                        businessInformation[
                            'business_name'],
                      ),
                    ),
                    _InfoRow(
                      label: 'เลขทะเบียน',
                      value: _value(
                        businessInformation[
                            'registration_number'],
                      ),
                    ),
                    _InfoRow(
                      label: 'ประเภทกิจการ',
                      value: _value(
                        businessInformation[
                            'business_type'],
                      ),
                    ),
                    _InfoRow(
                      label: 'ประเทศ',
                      value: _value(
                        businessInformation[
                            'country_code'],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'เอกสารกิจการ',
                icon: Icons.description_outlined,
                child: _DocumentPreview(
                  document: document,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color:
                          theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'การส่งข้อมูลจะเป็นการสร้างคำขอ '
                        'เข้าสู่กระบวนการตรวจสอบกิจการ '
                        'ยังไม่ถือว่าได้รับการอนุมัติ '
                        'หรือได้รับสถานะ Verified',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'ส่งคำขอตรวจสอบ',
                  icon: Icons.send_rounded,
                  onPressed: onSubmit == null
                      ? () =>
                          _showSubmitConfirmation(
                            context,
                          )
                      : () =>
                          _showSubmitConfirmation(
                            context,
                          ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  child:
                      const Text('แก้ไขข้อมูล'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmation(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('ยืนยันการส่งคำขอ'),
          content: const Text(
            'คุณตรวจสอบข้อมูลกิจการและเอกสาร '
            'เรียบร้อยแล้วใช่หรือไม่?\n\n'
            'เมื่อยืนยัน ระบบจะนำข้อมูลเข้าสู่ '
            'กระบวนการตรวจสอบกิจการ',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child:
                  const Text('กลับไปตรวจสอบ'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                final submit = onSubmit;

                if (submit == null) {
                  _showBackendPendingMessage(
                    context,
                  );
                  return;
                }

                await _submit(
                  context,
                  submit,
                );
              },
              child:
                  const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    Future<void> Function(
      Map<String, dynamic>,
    ) submit,
  ) async {
    try {
      await submit(
        businessInformation,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งคำขอตรวจสอบกิจการเรียบร้อยแล้ว',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถส่งคำขอได้: $error',
          ),
        ),
      );
    }
  }

  void _showBackendPendingMessage(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ระบบยังไม่ได้เชื่อม Business Registration UseCase',
        ),
      ),
    );
  }

  static String _value(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    return text.isEmpty ? '-' : text;
  }
}

class _SectionCard extends StatelessWidget {
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant,
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
                color:
                    theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview
    extends StatelessWidget {
  const _DocumentPreview({
    required this.document,
  });

  final Map<String, dynamic>? document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentDocument = document;

    if (currentDocument == null) {
      return Text(
        'ไม่พบเอกสาร',
        style: theme.textTheme.bodyMedium
            ?.copyWith(
          color:
              theme.colorScheme.error,
        ),
      );
    }

    final name =
        currentDocument['name']
                ?.toString() ??
            '-';

    final mimeType =
        currentDocument['mime_type']
                ?.toString() ??
            '-';

    final extension =
        currentDocument['extension']
                ?.toString() ??
            '-';

    final rawBytes =
        currentDocument['bytes'];

    final Uint8List? bytes =
        rawBytes is Uint8List
            ? rawBytes
            : null;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (bytes != null)
          ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, _, _) =>
                      const _FileIcon(),
            ),
          )
        else
          const _FileIcon(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: theme.textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                mimeType,
                style:
                    theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'ประเภทไฟล์: .$extension',
                style: theme.textTheme
                    .bodySmall
                    ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.description_outlined,
        size: 32,
      ),
    );
  }
}