import 'package:flutter/material.dart';

import '../../../../../core/services/document_picker_service.dart';
import '../widgets/document_upload_card.dart';

final class IdentityCardPage extends StatefulWidget {
  const IdentityCardPage({
    super.key,
  });

  @override
  State<IdentityCardPage> createState() =>
      _IdentityCardPageState();
}

final class _IdentityCardPageState
    extends State<IdentityCardPage> {
  String? _frontFileName;
  String? _backFileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('บัตรประชาชน'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final horizontalPadding =
                constraints.maxWidth >= 900
                    ? 32.0
                    : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    40,
                  ),
                  children: [
                    _IdentityCardIntro(
                      theme: theme,
                    ),
                    const SizedBox(height: 24),
                    DocumentUploadCard(
                      icon: Icons.badge_outlined,
                      title: 'บัตรประชาชน',
                      description:
                          'ใช้สำหรับยืนยันตัวตนตามกฎหมาย '
                          'รองรับการตรวจสอบผ่านระบบ KYC '
                          'ของ Kao ID และผู้ให้บริการภายนอก',
                      status: 'not_started',
                      statusColor: Colors.orange,
                      statusIcon:
                          Icons.hourglass_empty,
                      expiryText: '-',
                      frontButtonText:
                          'เลือกด้านหน้า',
                      onUploadFront: _pickFront,
                      backButtonText:
                          'เลือกด้านหลัง',
                      onUploadBack: _pickBack,
                      frontFileName:
                          _frontFileName,
                      frontFileSize: null,
                      onChangeFrontFile:
                          _pickFront,
                      backFileName:
                          _backFileName,
                      backFileSize: null,
                      onChangeBackFile:
                          _pickBack,
                    ),
                    const SizedBox(height: 20),
                    _DocumentRequirementCard(
                      theme: theme,
                    ),
                    const SizedBox(height: 20),
                    _PrivacyNotice(
                      theme: theme,
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

  // ===========================================================================
  // DOCUMENT PICKING
  // ===========================================================================

  Future<void> _pickFront() async {
    const picker = DocumentPickerService();

    final document = await picker.pickImage();

    if (!mounted || document == null) {
      return;
    }

    setState(() {
      _frontFileName = document.name;
    });

    if (!mounted) {
      return;
    }

    _showSelectedFileMessage(
      'เลือกไฟล์ด้านหน้าสำเร็จ',
      document.name,
    );
  }

  Future<void> _pickBack() async {
    const picker = DocumentPickerService();

    final document = await picker.pickImage();

    if (!mounted || document == null) {
      return;
    }

    setState(() {
      _backFileName = document.name;
    });

    if (!mounted) {
      return;
    }

    _showSelectedFileMessage(
      'เลือกไฟล์ด้านหลังสำเร็จ',
      document.name,
    );
  }

  void _showSelectedFileMessage(
    String title,
    String fileName,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 2),
              Text(
                fileName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ],
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }
}

// ==============================================================================
// INTRO
// ==============================================================================

final class _IdentityCardIntro
    extends StatelessWidget {
  const _IdentityCardIntro({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  colorScheme.primaryContainer,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: colorScheme
                  .onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ยืนยันตัวตนด้วยบัตรประชาชน',
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'กรุณาเตรียมบัตรประชาชนตัวจริง '
                  'และถ่ายภาพให้เห็นข้อมูลครบถ้วน '
                  'ชัดเจน และไม่มีแสงสะท้อน',
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                    height: 1.5,
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

// ==============================================================================
// REQUIREMENTS
// ==============================================================================

final class _DocumentRequirementCard
    extends StatelessWidget {
  const _DocumentRequirementCard({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color:
              colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อกำหนดเอกสาร',
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _RequirementItem(
              icon:
                  Icons.check_circle_outline,
              text:
                  'ภาพด้านหน้าและด้านหลังต้องชัดเจน',
            ),
            const SizedBox(height: 12),
            const _RequirementItem(
              icon: Icons.image_outlined,
              text:
                  'ต้องเห็นข้อมูลบนบัตรครบถ้วน',
            ),
            const SizedBox(height: 12),
            const _RequirementItem(
              icon: Icons.wb_sunny_outlined,
              text:
                  'หลีกเลี่ยงแสงสะท้อนและภาพเบลอ',
            ),
            const SizedBox(height: 12),
            const _RequirementItem(
              icon: Icons.lock_outline,
              text:
                  'ข้อมูลจะถูกใช้สำหรับการตรวจสอบตัวตน',
            ),
          ],
        ),
      ),
    );
  }
}

final class _RequirementItem
    extends StatelessWidget {
  const _RequirementItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// PRIVACY
// ==============================================================================

final class _PrivacyNotice
    extends StatelessWidget {
  const _PrivacyNotice({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme
            .primaryContainer
            .withValues(alpha: 0.35),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color:
                colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ข้อมูลเอกสารใช้สำหรับการยืนยันตัวตน '
              'และควรส่งผ่านระบบของ Kao ID เท่านั้น',
              style: theme
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                color: colorScheme
                    .onPrimaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}