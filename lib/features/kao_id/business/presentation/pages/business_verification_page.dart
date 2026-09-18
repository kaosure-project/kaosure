import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessVerificationPage extends StatelessWidget {
  const BusinessVerificationPage({
    super.key,
    required this.businessInformation,
  });

  static const routeName = '/kao-id/business/verification';

  final Map<String, dynamic> businessInformation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final businessName =
        _value(businessInformation['business_name']);

    final registrationNumber =
        _value(
          businessInformation['registration_number'],
        );

    final document =
        businessInformation['registration_document']
            as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันกิจการ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'พร้อมเข้าสู่การตรวจสอบ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'ตรวจสอบข้อมูลเบื้องต้นเรียบร้อยแล้ว '
                'ขั้นตอนถัดไปคือการส่งข้อมูลเข้าสู่กระบวนการ '
                'ตรวจสอบกิจการของ Kao ID',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              _BusinessSummaryCard(
                businessName: businessName,
                registrationNumber: registrationNumber,
                documentName: document?['name']?.toString(),
              ),

              const SizedBox(height: 20),

              _VerificationStep(
                number: '1',
                title: 'ตรวจสอบข้อมูลกิจการ',
                description:
                    'ตรวจสอบข้อมูลที่ผู้สมัครระบุและเอกสารประกอบ',
              ),

              const SizedBox(height: 12),

              _VerificationStep(
                number: '2',
                title: 'ตรวจสอบผู้มีสิทธิ์',
                description:
                    'ตรวจสอบความสัมพันธ์ระหว่างผู้สมัครกับกิจการ',
              ),

              const SizedBox(height: 12),

              _VerificationStep(
                number: '3',
                title: 'ประเมินผลการตรวจสอบ',
                description:
                    'กำหนดสถานะตามผลการตรวจสอบและนโยบายความเสี่ยง',
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'การส่งข้อมูลไม่ได้หมายความว่ากิจการได้รับการอนุมัติ '
                        'ระบบจะแสดงสถานะตามผลการตรวจสอบจริง',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'ส่งเข้าสู่การตรวจสอบ',
                  icon: Icons.send_rounded,
                  onPressed: () {
                    _showConfirmation(context);
                  },
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ย้อนกลับ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการส่งตรวจสอบ'),
          content: const Text(
            'คุณยืนยันว่าข้อมูลกิจการและเอกสารที่ส่ง '
            'เป็นข้อมูลจริงและถูกต้องใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('ตรวจสอบอีกครั้ง'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                Navigator.of(context).pushNamed(
                  '/kao-id/business/verification/status',
                  arguments: businessInformation,
                );
              },
              icon: const Icon(
                Icons.check_rounded,
              ),
              label: const Text('ยืนยันและส่ง'),
            ),
          ],
        );
      },
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

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({
    required this.businessName,
    required this.registrationNumber,
    required this.documentName,
  });

  final String businessName;
  final String registrationNumber;
  final String? documentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปข้อมูล',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          _SummaryRow(
            icon: Icons.storefront_outlined,
            label: 'กิจการ',
            value: businessName,
          ),

          const SizedBox(height: 14),

          _SummaryRow(
            icon: Icons.badge_outlined,
            label: 'เลขทะเบียน',
            value: registrationNumber,
          ),

          const SizedBox(height: 14),

          _SummaryRow(
            icon: Icons.description_outlined,
            label: 'เอกสาร',
            value: documentName ?? 'ไม่พบเอกสาร',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}