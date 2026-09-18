import 'package:flutter/material.dart';

import '../../domain/entities/business_registration.dart';

/// Business Registration UI
///
/// หน้านี้เป็น Presentation Layer เท่านั้น
/// ไม่เรียก Supabase โดยตรง และไม่ผูกกับ Provider/Controller ใด ๆ
/// เพื่อให้สามารถเชื่อมกับ UseCase/Controller ของ Kao ID ได้โดยไม่เกิด
/// coupling ระหว่าง UI กับ Data Layer
///
/// ตัวอย่างการเชื่อม:
/// BusinessRegistrationPage(
///   initialRegistration: registration,
///   onSaveDraft: (value) async {
///     return useCases.createDraft(value);
///   },
///   onUpdateDraft: (value) async {
///     return useCases.updateDraft(value);
///   },
///   onAttachDocument: (registrationId) async {
///     // เปิด picker -> upload -> return documentId
///     return documentId;
///   },
///   onSubmit: (registrationId) async {
///     return useCases.submit(registrationId);
///   },
/// )
class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({
    super.key,
    this.initialRegistration,
    this.onSaveDraft,
    this.onUpdateDraft,
    this.onAttachDocument,
    this.onSubmit,
    this.onCancel,
  });

  static const String routeName = '/kao-id/business/register';

  final BusinessRegistration? initialRegistration;

  final Future<BusinessRegistration> Function(
    BusinessRegistration registration,
  )? onSaveDraft;

  final Future<BusinessRegistration> Function(
    BusinessRegistration registration,
  )? onUpdateDraft;

  /// ควรทำ upload จริงใน Controller/UseCase layer แล้วคืน documentId
  final Future<String?> Function(String registrationId)?
      onAttachDocument;

  final Future<BusinessRegistration> Function(
    String registrationId,
  )? onSubmit;

  final Future<void> Function(String registrationId)? onCancel;

  @override
  State<BusinessRegistrationPage> createState() =>
      _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState
    extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameController;
  late final TextEditingController _registrationNumberController;
  late final TextEditingController _businessCategoryController;
  late final TextEditingController _descriptionController;

  BusinessRegistration? _registration;
  String _businessType = 'registered_business';

  bool _isSaving = false;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isCancelling = false;

  BusinessRegistration get _currentRegistration {
    final current = _registration;

    if (current != null) {
      return current;
    }

    return BusinessRegistration(
      userId: '',
      businessType: _businessType,
      businessName: _businessNameController.text.trim(),
      registrationNumber:
          _registrationNumberController.text.trim(),
      businessCategory:
          _businessCategoryController.text.trim(),
      businessDescription:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
    );
  }

  bool get _isExisting =>
      _registration?.id != null &&
      _registration!.id!.trim().isNotEmpty;

  bool get _isDraft =>
      _registration?.status ==
          BusinessRegistrationStatus.draft ||
      _registration == null;

  bool get _canEdit =>
      _isDraft &&
      !_isSaving &&
      !_isUploading &&
      !_isSubmitting &&
      !_isCancelling;

  @override
  void initState() {
    super.initState();

    _registration = widget.initialRegistration;

    final registration = widget.initialRegistration;

    _businessType =
        registration?.businessType ?? 'registered_business';

    _businessNameController = TextEditingController(
      text: registration?.businessName ?? '',
    );

    _registrationNumberController = TextEditingController(
      text: registration?.registrationNumber ?? '',
    );

    _businessCategoryController = TextEditingController(
      text: registration?.businessCategory ?? '',
    );

    _descriptionController = TextEditingController(
      text: registration?.businessDescription ?? '',
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _businessCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registration = _registration;

    return Scaffold(
      backgroundColor: _KaoColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _KaoColors.background,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Text(
          'Business Registration',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                8,
                isWide ? 32 : 16,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PageHeader(
                        registration: registration,
                      ),
                      const SizedBox(height: 20),
                      if (registration != null &&
                          registration.status !=
                              BusinessRegistrationStatus.draft)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 20),
                          child: _StatusBanner(
                            registration: registration,
                          ),
                        ),
                      _ProgressCard(
                        registration: registration,
                      ),
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildFormCard(theme),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: _buildSidePanel(theme),
                            ),
                          ],
                        )
                      else ...[
                        _buildFormCard(theme),
                        const SizedBox(height: 16),
                        _buildSidePanel(theme),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return _SectionCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.business_outlined,
              title: 'Business information',
              subtitle:
                  'กรอกข้อมูลกิจการให้ตรงกับเอกสารทางกฎหมาย',
            ),
            const SizedBox(height: 24),
            _KaoTextField(
              controller: _businessNameController,
              label: 'ชื่อกิจการ',
              hint: 'เช่น Kao Vintage Co., Ltd.',
              enabled: _canEdit,
              requiredField: true,
              prefixIcon: Icons.storefront_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อกิจการ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _KaoDropdown<String>(
                    value: _businessType,
                    label: 'ประเภทการประกอบธุรกิจ',
                    enabled: _canEdit,
                    items: const [
                      DropdownMenuItem(
                        value: 'registered_business',
                        child: Text('ธุรกิจจดทะเบียน'),
                      ),
                      DropdownMenuItem(
                        value: 'business_document',
                        child: Text('มีเอกสารรับรองธุรกิจ'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _businessType = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _KaoTextField(
                    controller: _registrationNumberController,
                    label: 'เลขทะเบียน / เลขอ้างอิง',
                    hint: 'กรอกเลขทะเบียนกิจการ',
                    enabled: _canEdit,
                    requiredField: true,
                    prefixIcon: Icons.numbers_outlined,
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'กรุณากรอกเลขทะเบียน';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _KaoTextField(
              controller: _businessCategoryController,
              label: 'หมวดหมู่ธุรกิจ',
              hint: 'เช่น ค้าปลีก / ของสะสม / อิเล็กทรอนิกส์',
              enabled: _canEdit,
              requiredField: true,
              prefixIcon: Icons.category_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุหมวดหมู่ธุรกิจ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _KaoTextField(
              controller: _descriptionController,
              label: 'รายละเอียดกิจการ',
              hint:
                  'อธิบายลักษณะธุรกิจ สินค้า หรือบริการโดยสรุป',
              enabled: _canEdit,
              prefixIcon: Icons.notes_outlined,
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 24),
            _DocumentCard(
              registration: _registration,
              enabled: _canEdit,
              isUploading: _isUploading,
              onTap: _attachDocument,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(ThemeData theme) {
    return Column(
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.verified_user_outlined,
                title: 'Verification',
                subtitle:
                    'เอกสารจะถูกตรวจสอบก่อนอนุมัติบัญชีธุรกิจ',
              ),
              const SizedBox(height: 20),
              const _VerificationStep(
                icon: Icons.description_outlined,
                title: 'ข้อมูลกิจการ',
                subtitle: 'ตรวจสอบชื่อและเลขทะเบียน',
              ),
              const _StepConnector(),
              _VerificationStep(
                icon: Icons.upload_file_outlined,
                title: 'เอกสารธุรกิจ',
                subtitle: _registration?.hasDocument == true
                    ? 'อัปโหลดแล้ว'
                    : 'ยังไม่ได้แนบเอกสาร',
                isDone: _registration?.hasDocument == true,
              ),
              const _StepConnector(),
              _VerificationStep(
                icon: Icons.fact_check_outlined,
                title: 'ตรวจสอบ',
                subtitle: _verificationSubtitle,
                isDone: _registration?.isApproved == true,
                isActive:
                    _registration?.isUnderReview == true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _InfoCard(),
      ],
    );
  }

  String get _verificationSubtitle {
    final status = _registration?.status;

    switch (status) {
      case BusinessRegistrationStatus.underReview:
        return 'อยู่ระหว่างตรวจสอบ';
      case BusinessRegistrationStatus.requiresAction:
        return 'ต้องแก้ไขข้อมูล';
      case BusinessRegistrationStatus.approved:
        return 'อนุมัติแล้ว';
      case BusinessRegistrationStatus.rejected:
        return 'คำขอถูกปฏิเสธ';
      case BusinessRegistrationStatus.submitted:
        return 'ส่งคำขอแล้ว';
      case BusinessRegistrationStatus.draft:
      case null:
        return 'รอส่งคำขอ';
    }
  }

  Widget _buildBottomBar() {
    final canInteract =
        !_isSaving &&
        !_isUploading &&
        !_isSubmitting &&
        !_isCancelling;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: _KaoColors.divider,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1120,
            ),
            child: Row(
              children: [
                if (_isExisting && _isDraft)
                  OutlinedButton.icon(
                    onPressed:
                        canInteract ? _confirmCancel : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ยกเลิก'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _KaoColors.danger,
                      side: const BorderSide(
                        color: _KaoColors.danger,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                const Spacer(),
                OutlinedButton(
                  onPressed:
                      canInteract && _isDraft
                          ? _saveDraft
                          : null,
                  child: Text(
                    _isExisting
                        ? 'บันทึกการแก้ไข'
                        : 'บันทึกฉบับร่าง',
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed:
                      canInteract && _isDraft
                          ? _submit
                          : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                          size: 18,
                        ),
                  label: const Text('ส่งคำขอ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _KaoColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage(
        'กรุณาตรวจสอบข้อมูลที่จำเป็น',
        isError: true,
      );
      return;
    }

    final registration = _buildRegistration();

    setState(() => _isSaving = true);

    try {
      final saved = _isExisting
          ? await widget.onUpdateDraft?.call(registration)
          : await widget.onSaveDraft?.call(registration);

      if (!mounted) return;

      if (saved != null) {
        setState(() => _registration = saved);
        _showMessage('บันทึกข้อมูลเรียบร้อยแล้ว');
      } else {
        _showMessage(
          'UI พร้อมแล้ว แต่ยังไม่ได้เชื่อม UseCase',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'ไม่สามารถบันทึกข้อมูลได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  BusinessRegistration _buildRegistration() {
    final current = _currentRegistration;

    return current.copyWith(
      businessType: _businessType,
      businessName: _businessNameController.text.trim(),
      registrationNumber:
          _registrationNumberController.text.trim(),
      businessCategory:
          _businessCategoryController.text.trim(),
      businessDescription:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
    );
  }

  Future<void> _attachDocument() async {
    if (!_isExisting) {
      _showMessage(
        'กรุณาบันทึกฉบับร่างก่อนแนบเอกสาร',
        isError: true,
      );
      return;
    }

    final registrationId = _registration?.id;

    if (registrationId == null ||
        registrationId.trim().isEmpty) {
      _showMessage(
        'ไม่พบ Registration ID',
        isError: true,
      );
      return;
    }

    if (widget.onAttachDocument == null) {
      _showMessage(
        'UI พร้อมแล้ว แต่ยังไม่ได้เชื่อมระบบอัปโหลดเอกสาร',
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final documentId =
          await widget.onAttachDocument!.call(registrationId);

      if (!mounted) return;

      if (documentId == null ||
          documentId.trim().isEmpty) {
        return;
      }

      setState(() {
        _registration = _registration?.copyWith(
          documentId: documentId,
          documentStatus:
              BusinessDocumentStatus.uploaded,
        );
      });

      _showMessage('อัปโหลดเอกสารเรียบร้อยแล้ว');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'ไม่สามารถอัปโหลดเอกสารได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage(
        'กรุณากรอกข้อมูลที่จำเป็นให้ครบ',
        isError: true,
      );
      return;
    }

    final registration = _buildRegistration();

    if (!registration.hasDocument) {
      _showMessage(
        'กรุณาแนบเอกสารธุรกิจก่อนส่งคำขอ',
        isError: true,
      );
      return;
    }

    if (!registration.canSubmit) {
      _showMessage(
        'ข้อมูลยังไม่พร้อมสำหรับการส่งคำขอ',
        isError: true,
      );
      return;
    }

    final registrationId = registration.id;

    if (registrationId == null ||
        registrationId.trim().isEmpty) {
      _showMessage(
        'กรุณาบันทึกฉบับร่างก่อนส่งคำขอ',
        isError: true,
      );
      return;
    }

    if (widget.onSubmit == null) {
      _showMessage(
        'UI พร้อมแล้ว แต่ยังไม่ได้เชื่อม Submit UseCase',
        isError: true,
      );
      return;
    }

    final confirmed = await _showSubmitConfirmation();

    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final submitted =
          await widget.onSubmit!.call(registrationId);

      if (!mounted) return;

      setState(() => _registration = submitted);

      _showMessage('ส่งคำขอเรียบร้อยแล้ว');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'ไม่สามารถส่งคำขอได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _showSubmitConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'ยืนยันการส่งคำขอ',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'เมื่อส่งแล้ว ข้อมูลจะเข้าสู่ขั้นตอนตรวจสอบ '
            'และอาจไม่สามารถแก้ไขข้อมูลบางส่วนได้',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ตรวจสอบอีกครั้ง'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยันส่งคำขอ'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _confirmCancel() async {
    final registrationId = _registration?.id;

    if (registrationId == null ||
        registrationId.trim().isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'ยกเลิกฉบับร่าง?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'ข้อมูลฉบับร่างและข้อมูลที่เกี่ยวข้องจะถูกยกเลิก',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ไม่ยกเลิก'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _KaoColors.danger,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    if (widget.onCancel == null) {
      _showMessage(
        'UI พร้อมแล้ว แต่ยังไม่ได้เชื่อม Cancel UseCase',
        isError: true,
      );
      return;
    }

    setState(() => _isCancelling = true);

    try {
      await widget.onCancel!.call(registrationId);

      if (!mounted) return;

      Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'ไม่สามารถยกเลิกได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? _KaoColors.danger : _KaoColors.primaryDark,
          content: Text(message),
        ),
      );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.registration,
  });

  final BusinessRegistration? registration;

  @override
  Widget build(BuildContext context) {
    final status = registration?.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _KaoColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: _KaoColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ยืนยันธุรกิจของคุณ',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Business Registration',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: _KaoColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (status != null)
              _StatusChip(status: status),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'กรอกข้อมูลกิจการ แนบเอกสาร และส่งคำขอเพื่อเปิดใช้ความสามารถสำหรับบัญชีธุรกิจบน Kao ID',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: _KaoColors.textSecondary,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.registration,
  });

  final BusinessRegistration? registration;

  @override
  Widget build(BuildContext context) {
    final hasInfo =
        registration != null &&
        registration!.businessName.trim().isNotEmpty &&
        registration!.registrationNumber.trim().isNotEmpty &&
        registration!.businessCategory.trim().isNotEmpty;

    final hasDocument = registration?.hasDocument == true;
    final submitted =
        registration?.status ==
                BusinessRegistrationStatus.submitted ||
            registration?.status ==
                BusinessRegistrationStatus.underReview ||
            registration?.status ==
                BusinessRegistrationStatus.approved;

    final completed = [
      hasInfo,
      hasDocument,
      submitted,
    ].where((value) => value).length;

    final progress = completed / 3;

    return _SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Application progress',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$completed / 3 ขั้นตอน',
                style: const TextStyle(
                  color: _KaoColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _KaoColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                _KaoColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStep(
                number: '01',
                title: 'ข้อมูลกิจการ',
                isDone: hasInfo,
              ),
              const _MiniStepDivider(),
              _MiniStep(
                number: '02',
                title: 'เอกสาร',
                isDone: hasDocument,
              ),
              const _MiniStepDivider(),
              _MiniStep(
                number: '03',
                title: 'ตรวจสอบ',
                isDone: submitted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.registration,
  });

  final BusinessRegistration registration;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(registration.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, color: config.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: config.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  config.description,
                  style: const TextStyle(
                    color: _KaoColors.textSecondary,
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
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.registration,
    required this.enabled,
    required this.isUploading,
    required this.onTap,
  });

  final BusinessRegistration? registration;
  final bool enabled;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDocument = registration?.hasDocument == true;
    final verified =
        registration?.isDocumentVerified == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasDocument
            ? _KaoColors.primary.withValues(alpha: 0.055)
            : _KaoColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDocument
              ? _KaoColors.primary.withValues(alpha: 0.25)
              : _KaoColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasDocument
                      ? _KaoColors.primary.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasDocument
                      ? Icons.description_rounded
                      : Icons.upload_file_rounded,
                  color: hasDocument
                      ? _KaoColors.primaryDark
                      : _KaoColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เอกสารรับรองธุรกิจ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'แนบเอกสารที่ใช้ยืนยันข้อมูลกิจการ',
                      style: TextStyle(
                        color: _KaoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (verified)
                const Icon(
                  Icons.verified_rounded,
                  color: _KaoColors.success,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasDocument)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: _KaoColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verified
                        ? 'เอกสารผ่านการตรวจสอบแล้ว'
                        : 'แนบเอกสารแล้ว รอการตรวจสอบ',
                    style: const TextStyle(
                      color: _KaoColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: enabled ? onTap : null,
                  child: const Text('เปลี่ยนเอกสาร'),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: enabled && !isUploading
                    ? onTap
                    : null,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                      ),
                label: Text(
                  isUploading
                      ? 'กำลังอัปโหลด...'
                      : 'เลือกและอัปโหลดเอกสาร',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _KaoColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _KaoColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _KaoColors.primaryDark,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _KaoColors.textSecondary,
                  fontSize: 12.5,
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

class _KaoTextField extends StatelessWidget {
  const _KaoTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.prefixIcon,
    this.requiredField = false,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;
  final IconData prefixIcon;
  final bool requiredField;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 8,
          ),
          child: Icon(
            prefixIcon,
            size: 21,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
        ),
        filled: true,
        fillColor: enabled
            ? _KaoColors.surfaceMuted
            : _KaoColors.disabled,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.danger,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _KaoDropdown<T> extends StatelessWidget {
  const _KaoDropdown({
    required this.value,
    required this.label,
    required this.enabled,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final bool enabled;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled
            ? _KaoColors.surfaceMuted
            : _KaoColors.disabled,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _KaoColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isActive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? _KaoColors.success
        : isActive
            ? _KaoColors.primary
            : _KaoColors.textSecondary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDone
                ? Icons.check_rounded
                : icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _KaoColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.only(left: 19),
      color: _KaoColors.divider,
    );
  }
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({
    required this.number,
    required this.title,
    required this.isDone,
  });

  final String number;
  final String title;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? _KaoColors.primary
                  : _KaoColors.surfaceMuted,
            ),
            child: isDone
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : Text(
                    number,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _KaoColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isDone ? FontWeight.w700 : FontWeight.w500,
                color: isDone
                    ? _KaoColors.textPrimary
                    : _KaoColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStepDivider extends StatelessWidget {
  const _MiniStepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 1,
      color: _KaoColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _KaoColors.infoBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _KaoColors.info.withValues(alpha: 0.18),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                size: 20,
                color: _KaoColors.info,
              ),
              SizedBox(width: 8),
              Text(
                'ข้อมูลของคุณปลอดภัย',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'ข้อมูลธุรกิจจะถูกใช้เพื่อการยืนยันตัวตนและการตรวจสอบสิทธิ์ของบัญชีธุรกิจเท่านั้น',
            style: TextStyle(
              color: _KaoColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final BusinessRegistrationStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 15,
            color: config.foreground,
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String title;
  final String description;
  final IconData icon;
  final Color foreground;
  final Color background;
}

_StatusConfig _statusConfig(
  BusinessRegistrationStatus status,
) {
  switch (status) {
    case BusinessRegistrationStatus.draft:
      return const _StatusConfig(
        label: 'ฉบับร่าง',
        title: 'ยังไม่ส่งคำขอ',
        description:
            'คุณสามารถแก้ไขข้อมูลและแนบเอกสารก่อนส่งคำขอได้',
        icon: Icons.edit_note_rounded,
        foreground: _KaoColors.textSecondary,
        background: Color(0xFFF3F4F6),
      );
    case BusinessRegistrationStatus.submitted:
      return const _StatusConfig(
        label: 'ส่งแล้ว',
        title: 'ส่งคำขอแล้ว',
        description:
            'ระบบได้รับคำขอแล้วและกำลังเตรียมเข้าสู่ขั้นตอนตรวจสอบ',
        icon: Icons.send_rounded,
        foreground: _KaoColors.info,
        background: Color(0xFFEFF6FF),
      );
    case BusinessRegistrationStatus.underReview:
      return const _StatusConfig(
        label: 'กำลังตรวจสอบ',
        title: 'อยู่ระหว่างตรวจสอบ',
        description:
            'ทีมตรวจสอบกำลังตรวจสอบข้อมูลและเอกสารของกิจการ',
        icon: Icons.hourglass_top_rounded,
        foreground: _KaoColors.warning,
        background: Color(0xFFFFF7ED),
      );
    case BusinessRegistrationStatus.requiresAction:
      return const _StatusConfig(
        label: 'ต้องแก้ไข',
        title: 'ต้องดำเนินการเพิ่มเติม',
        description:
            'กรุณาตรวจสอบรายละเอียดและแก้ไขข้อมูลตามที่ระบบแจ้ง',
        icon: Icons.warning_amber_rounded,
        foreground: Color(0xFFB45309),
        background: Color(0xFFFFF7ED),
      );
    case BusinessRegistrationStatus.approved:
      return const _StatusConfig(
        label: 'อนุมัติแล้ว',
        title: 'ธุรกิจได้รับการอนุมัติ',
        description:
            'การยืนยันธุรกิจเสร็จสมบูรณ์แล้ว',
        icon: Icons.verified_rounded,
        foreground: _KaoColors.success,
        background: Color(0xFFF0FDF4),
      );
    case BusinessRegistrationStatus.rejected:
      return const _StatusConfig(
        label: 'ไม่อนุมัติ',
        title: 'คำขอไม่ผ่านการตรวจสอบ',
        description:
            'ตรวจสอบเหตุผลจากระบบและดำเนินการส่งคำขอใหม่ตามเงื่อนไข',
        icon: Icons.cancel_outlined,
        foreground: _KaoColors.danger,
        background: Color(0xFFFEF2F2),
      );
  }
}

class _KaoColors {
  static const primary = Color(0xFF58C84D);
  static const primaryDark = Color(0xFF36922B);
  static const danger = Color(0xFFD62828);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF2563EB);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
  static const background = Color(0xFFF8F9FB);
  static const surfaceMuted = Color(0xFFF9FAFB);
  static const disabled = Color(0xFFF3F4F6);
  static const infoBackground = Color(0xFFEFF6FF);
}
