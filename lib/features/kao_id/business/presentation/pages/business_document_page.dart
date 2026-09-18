import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../../core/services/document_picker_service.dart';
import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessDocumentPage extends StatefulWidget {
  const BusinessDocumentPage({
    super.key,
    required this.businessInformation,
  });

  static const String routeName =
      '/kao-id/business/document';

  final Map<String, dynamic> businessInformation;

  @override
  State<BusinessDocumentPage> createState() =>
      _BusinessDocumentPageState();
}

class _BusinessDocumentPageState
    extends State<BusinessDocumentPage> {
  final DocumentPickerService _documentPickerService =
      DocumentPickerService();

  PickedDocument? _registrationDocument;
  bool _isPicking = false;

  Future<void> _pickRegistrationDocument() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final document =
          await _documentPickerService.pickImage();

      if (!mounted) {
        return;
      }

      if (document == null) {
        setState(() {
          _isPicking = false;
        });
        return;
      }

      final mimeType =
          _resolveMimeType(document.extension);

      final resolvedDocument = PickedDocument(
        name: document.name,
        bytes: document.bytes,
        extension: document.extension,
        mimeType: mimeType,
      );

      setState(() {
        _registrationDocument = resolvedDocument;
        _isPicking = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPicking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเลือกเอกสารได้: $error',
          ),
        ),
      );
    }
  }

  void _removeRegistrationDocument() {
    setState(() {
      _registrationDocument = null;
    });
  }

  void _continue() {
    final document = _registrationDocument;

    if (document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาแนบเอกสารยืนยันการประกอบกิจการ',
          ),
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      ...widget.businessInformation,
      'registration_document': {
        'name': document.name,
        'extension': document.extension,
        'mime_type': document.mimeType,
        'bytes': document.bytes,
      },
    };

    Navigator.of(context).pushNamed(
      '/kao-id/business/review',
      arguments: data,
    );
  }

  static String? _resolveMimeType(
    String extension,
  ) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เอกสารกิจการ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _StepHeader(
                theme: theme,
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 36,
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Text(
                  'เอกสารยืนยันกิจการ',
                  textAlign: TextAlign.center,
                  style: theme
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'แนบเอกสารที่ใช้ยืนยันการประกอบธุรกิจ '
                  'เพื่อใช้ในขั้นตอนตรวจสอบของ KaoSure',
                  textAlign: TextAlign.center,
                  style: theme
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    height: 1.5,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _DocumentCard(
                document: _registrationDocument,
                isLoading: _isPicking,
                onPick: _pickRegistrationDocument,
                onRemove:
                    _removeRegistrationDocument,
              ),
              const SizedBox(height: 20),
              _SecurityInformationCard(
                theme: theme,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'ตรวจสอบข้อมูล',
                  icon:
                      Icons.arrow_forward_rounded,
                  onPressed: _continue,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(),
                  child: const Text(
                    'ย้อนกลับ',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '3',
            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              color:
                  theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'เอกสารประกอบ',
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ขั้นตอนที่ 3 จาก 6',
                style: theme
                    .textTheme
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
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 3 / 6,
              minHeight: 7,
              backgroundColor: theme
                  .colorScheme
                  .surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityInformationCard
    extends StatelessWidget {
  const _SecurityInformationCard({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme
                  .colorScheme
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.security_outlined,
              color: theme
                  .colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อกำหนดเอกสาร',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เอกสารจะต้องเป็นของกิจการที่สมัคร '
                  'และข้อมูลควรตรงกับข้อมูลที่กรอกไว้ '
                  'ระบบอาจขอเอกสารเพิ่มเติมตามผลการตรวจสอบ',
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    height: 1.45,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
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

class _DocumentCard
    extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  final PickedDocument? document;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final documentValue = document;

    if (documentValue == null) {
      return InkWell(
        onTap: isLoading ? null : onPick,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: theme
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'แนบเอกสารทะเบียนการค้า',
                textAlign: TextAlign.center,
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'รองรับ JPG, JPEG และ PNG',
                textAlign: TextAlign.center,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                  ),
                  label:
                      const Text('เลือกเอกสาร'),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.primaryContainer,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary
              .withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          _DocumentPreview(
            bytes: documentValue.bytes,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  documentValue.name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  documentValue.mimeType ??
                      'ไม่ทราบประเภทไฟล์',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatBytes(documentValue.bytes.length)}'
                  ' • .${documentValue.extension}',
                  style: theme
                      .textTheme
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
          IconButton(
            tooltip: 'เปลี่ยนเอกสาร',
            onPressed:
                isLoading ? null : onPick,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'ลบเอกสาร',
            onPressed:
                isLoading ? null : onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DocumentPreview
    extends StatelessWidget {
  const _DocumentPreview({
    required this.bytes,
  });

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.memory(
        bytes,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 64,
            height: 64,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: const Icon(
              Icons.description_outlined,
            ),
          );
        },
      ),
    );
  }
}