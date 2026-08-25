import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../application/providers/kyc_provider.dart';
import '../../domain/entities/passport.dart';
import '../../domain/enums/verification_status.dart';

import '../../../../../core/services/document_picker_service.dart';
import '../../../../../core/services/document_upload_service.dart';

final class PassportPage extends ConsumerStatefulWidget {
  const PassportPage({
    super.key,
  });

  @override
  ConsumerState<PassportPage> createState() =>
      _PassportPageState();
}

final class _PassportPageState
    extends ConsumerState<PassportPage> {
  final _formKey = GlobalKey<FormState>();

  final _passportController =
      TextEditingController();

  DateTime? _issuedDate;
  DateTime? _expiryDate;

  String? _fileName;
  Uint8List? _fileBytes;

  bool _isLoading = false;

  @override
  void dispose() {
    _passportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        title: const Text(
          'หนังสือเดินทาง',
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 760,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  40,
                ),
                children: [
                  _buildHeader(
                    theme,
                    colors,
                  ),

                  const SizedBox(height: 20),

                  _buildPassportNumberField(
                    theme,
                    colors,
                  ),

                  const SizedBox(height: 16),

                  _buildDateSection(
                    theme,
                    colors,
                  ),

                  const SizedBox(height: 16),

                  _buildFileSection(
                    theme,
                    colors,
                  ),

                  const SizedBox(height: 16),

                  _buildSecurityCard(
                    theme,
                    colors,
                  ),

                  const SizedBox(height: 24),

                  _buildSaveButton(
                    theme,
                    colors,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(
          alpha: 0.30,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: colors.onPrimary,
              size: 32,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'หนังสือเดินทาง',
                  style: theme
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'เพิ่มข้อมูลหนังสือเดินทางเพื่อใช้ยืนยันตัวตนของคุณ',
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color:
                        colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PASSPORT NUMBER
  // ===========================================================================

  Widget _buildPassportNumberField(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.badge_outlined,
            title: 'เลขหนังสือเดินทาง',
            subtitle:
                'กรอกหมายเลขตามหนังสือเดินทางของคุณ',
          ),

          const SizedBox(height: 18),

          TextFormField(
            controller: _passportController,
            enabled: !_isLoading,
            textCapitalization:
                TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'เช่น AA1234567',
              prefixIcon: const Icon(
                Icons.badge_outlined,
              ),
              filled: true,
              fillColor:
                  colors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide(
                  color:
                      colors.outlineVariant,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              final number =
                  value?.trim() ?? '';

              if (number.isEmpty) {
                return 'กรุณากรอกเลขหนังสือเดินทาง';
              }

              if (number.length < 6) {
                return 'เลขหนังสือเดินทางไม่ถูกต้อง';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DATES
  // ===========================================================================

  Widget _buildDateSection(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.calendar_month_outlined,
            title: 'ข้อมูลวันที่',
            subtitle:
                'วันที่ออกและวันหมดอายุของหนังสือเดินทาง',
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    _DateButton(
                      label: 'วันที่ออก',
                      value: _issuedDate,
                      icon:
                          Icons.event_available_outlined,
                      onTap:
                          _pickIssuedDate,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    _DateButton(
                      label: 'วันหมดอายุ',
                      value: _expiryDate,
                      icon:
                          Icons.event_busy_outlined,
                      onTap:
                          _pickExpiryDate,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'วันที่ออก',
                      value: _issuedDate,
                      icon:
                          Icons.event_available_outlined,
                      onTap:
                          _pickIssuedDate,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _DateButton(
                      label: 'วันหมดอายุ',
                      value: _expiryDate,
                      icon:
                          Icons.event_busy_outlined,
                      onTap:
                          _pickExpiryDate,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FILE
  // ===========================================================================

  Widget _buildFileSection(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.upload_file_outlined,
            title: 'เอกสารหนังสือเดินทาง',
            subtitle:
                'อัปโหลดภาพหน้าหนังสือเดินทางที่เห็นข้อมูลชัดเจน',
          ),

          const SizedBox(height: 18),

          if (_fileName == null)
            InkWell(
              onTap: _isLoading
                  ? null
                  : _pickPassport,
              borderRadius:
                  BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: colors
                      .primaryContainer
                      .withValues(alpha: 0.20),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primary
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration:
                          BoxDecoration(
                        color: colors.primary
                            .withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'เพิ่มรูปหนังสือเดินทาง',
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'แตะเพื่อเลือกไฟล์จากอุปกรณ์',
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
            )
          else
            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors
                    .surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color:
                      colors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: colors
                          .primaryContainer,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color:
                          colors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          _fileName!,
                          maxLines: 1,
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
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          'พร้อมสำหรับการส่งตรวจสอบ',
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

                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : _pickPassport,
                    tooltip: 'เปลี่ยนไฟล์',
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECURITY
  // ===========================================================================

  Widget _buildSecurityCard(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant,
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
              color: colors.primary
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_outlined,
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
                  'ข้อมูลของคุณได้รับการปกป้อง',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'เอกสารจะถูกจัดเก็บในพื้นที่ KYC แบบ Private และใช้สำหรับกระบวนการยืนยันตัวตนเท่านั้น',
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                        colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SAVE BUTTON
  // ===========================================================================

  Widget _buildSaveButton(
    ThemeData theme,
    ColorScheme colors,
  ) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed:
            _isLoading ? null : _savePassport,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.check_circle_outline,
              ),
        label: Text(
          _isLoading
              ? 'กำลังบันทึก...'
              : 'บันทึกหนังสือเดินทาง',
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PICK FILE
  // ===========================================================================

  Future<void> _pickPassport() async {
    const picker =
        DocumentPickerService();

    final document =
        await picker.pickImage();

    if (document == null || !mounted) {
      return;
    }

    setState(() {
      _fileName = document.name;
      _fileBytes = document.bytes;
    });
  }

  // ===========================================================================
  // PICK ISSUED DATE
  // ===========================================================================

  Future<void> _pickIssuedDate() async {
    final date =
        await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate:
          _issuedDate ?? DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _issuedDate = date;
    });
  }

  // ===========================================================================
  // PICK EXPIRY DATE
  // ===========================================================================

  Future<void> _pickExpiryDate() async {
    final today = DateTime.now();

    final date =
        await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(
        today.year + 30,
        today.month,
        today.day,
      ),
      initialDate:
          _expiryDate ??
              DateTime(
                today.year + 5,
                today.month,
                today.day,
              ),
    );

    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDate = date;
    });
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> _savePassport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_issuedDate == null) {
      _showError(
        'กรุณาเลือกวันที่ออกหนังสือเดินทาง',
      );
      return;
    }

    if (_expiryDate == null) {
      _showError(
        'กรุณาเลือกวันหมดอายุหนังสือเดินทาง',
      );
      return;
    }

    if (!_expiryDate!.isAfter(_issuedDate!)) {
      _showError(
        'วันหมดอายุต้องอยู่หลังวันที่ออก',
      );
      return;
    }

    final bytes = _fileBytes;

    if (bytes == null ||
        bytes.isEmpty ||
        _fileName == null) {
      _showError(
        'กรุณาเลือกรูปหนังสือเดินทาง',
      );
      return;
    }

    final client =
        Supabase.instance.client;

    final user =
        client.auth.currentUser;

    if (user == null) {
      _showError(
        'ไม่พบผู้ใช้ที่เข้าสู่ระบบ',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? storagePath;

    try {
      // -----------------------------------------------------------------------
      // 1. Upload document
      // -----------------------------------------------------------------------

      final uploadService =
          DocumentUploadService(
        client,
      );

      storagePath =
          await uploadService.uploadBytes(
        bytes: bytes,
        fileName: _fileName!,
        folder: 'passport',
      );

      // -----------------------------------------------------------------------
      // 2. Create real Passport entity
      // -----------------------------------------------------------------------

      final now = DateTime.now();

      final passport =
          Passport(
        id: const Uuid().v4(),
        ownerId: user.id,
        documentType: 'passport',
        passportNumber:
            _passportController.text
                .trim()
                .toUpperCase(),
        fullName: '',
        countryCode: 'TH',

        // สำคัญ:
        // สถานะจริงหลังผู้ใช้ส่งข้อมูลเข้าระบบ
        // ต้องเป็น pending เพื่อให้ระบบตรวจสอบต่อ
        status:
            VerificationStatus.pending.value,

        issuedDate: _issuedDate,
        expiryDate: _expiryDate,

        verificationMethod:
            'manual',

        verifiedAt: null,
        verifiedBy: null,
        rejectedReason: null,
        deletedAt: null,

        filePath: storagePath,
        fileUrl: null,
        fileName: _fileName,
        fileSize: bytes.length,
        mimeType:
            _detectMimeType(_fileName!),
        uploadedAt: now,

        createdAt: now,
        updatedAt: now,
      );

      // -----------------------------------------------------------------------
      // 3. Submit through KYC use case
      //
      // ไม่เขียน Supabase ตรงจาก UI
      // ใช้ KYC architecture ที่มีอยู่แล้ว
      // -----------------------------------------------------------------------

      await ref
          .read(
            submitPassportUseCaseProvider,
          )
          .call(passport);

      if (!mounted) {
        return;
      }

      // -----------------------------------------------------------------------
      // 4. แจ้งสำเร็จ
      // -----------------------------------------------------------------------

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            'ส่งข้อมูลหนังสือเดินทางเรียบร้อยแล้ว',
          ),
        ),
      );

      // ส่ง true กลับให้ KycPage รู้ว่าข้อมูลเปลี่ยน
      Navigator.of(context).pop(true);
    } catch (error) {
      // -----------------------------------------------------------------------
      // ถ้า DB save ไม่สำเร็จ
      // ลบไฟล์ที่ upload ไปแล้ว เพื่อไม่ให้เกิด orphan file
      // -----------------------------------------------------------------------

      if (storagePath != null) {
        try {
          await DocumentUploadService(
            client,
          ).delete(
            storagePath: storagePath,
          );
        } catch (_) {
          // ไม่กลบ error หลัก
        }
      }

      if (!mounted) {
        return;
      }

      _showError(
        _friendlyError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _detectMimeType(
    String fileName,
  ) {
    final extension =
        fileName
            .split('.')
            .last
            .toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      default:
        return 'application/octet-stream';
    }
  }

  String _friendlyError(
    Object error,
  ) {
    if (error is AuthException) {
      return error.message;
    }

    if (error is PostgrestException) {
      return error.message;
    }

    return 'ไม่สามารถบันทึกข้อมูลหนังสือเดินทางได้';
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            Theme.of(context)
                .colorScheme
                .error,
        content: Text(message),
      ),
    );
  }
}

// =============================================================================
// SECTION CARD
// =============================================================================

final class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}

// =============================================================================
// SECTION TITLE
// =============================================================================

final class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);
    final colors =
        theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary
                .withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
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
                title,
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: theme
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                  color: colors
                      .onSurfaceVariant,
                  height: 1.4,
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
// DATE BUTTON
// =============================================================================

final class _DateButton
    extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);
    final colors =
        theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors
              .surfaceContainerLowest,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                colors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color: colors.primary
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: colors
                          .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value == null
                        ? 'เลือกวันที่'
                        : _formatDate(value!),
                    style: theme
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
                  colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}