import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessVerificationStatusPage extends StatelessWidget {
  const BusinessVerificationStatusPage({
    super.key,
    required this.businessInformation,
    required this.status,
  });

  static const routeName =
      '/kao-id/business/verification/status';

  final Map<String, dynamic> businessInformation;
  final String status;

  void _openCompleted(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(
      '/kao-id/business/completed',
      arguments: businessInformation,
    );
  }

  void _backToKaoId(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void _retry(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _statusConfig(status);
    final normalizedStatus = status.toLowerCase();

    if (normalizedStatus == 'approved') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }

        _openCompleted(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานะการตรวจสอบ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  config.icon,
                  size: 44,
                  color: config.foregroundColor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                config.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                config.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(
                  height: 1.5,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              _BusinessSummary(
                businessInformation:
                    businessInformation,
              ),

              const SizedBox(height: 20),

              _StatusCard(
                status: status,
                config: config,
              ),

              const SizedBox(height: 28),

              _ActionSection(
                status: status,
                onRetry: () => _retry(context),
                onBackToKaoId: () =>
                    _backToKaoId(context),
                onCompleted: () =>
                    _openCompleted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusConfig _statusConfig(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return const _StatusConfig(
          title: 'รอส่งตรวจสอบ',
          description:
              'ข้อมูลกิจการยังอยู่ในขั้นตอนเตรียมส่งเข้าสู่การตรวจสอบ',
          icon: Icons.schedule_rounded,
        );

      case 'under_review':
        return const _StatusConfig(
          title: 'กำลังตรวจสอบ',
          description:
              'ระบบได้รับข้อมูลแล้ว และอยู่ระหว่างการตรวจสอบกิจการ',
          icon: Icons.fact_check_outlined,
        );

      case 'approved':
        return const _StatusConfig(
          title: 'ตรวจสอบผ่าน',
          description:
              'กิจการผ่านกระบวนการตรวจสอบตามเงื่อนไขที่กำหนด',
          icon: Icons.verified_rounded,
        );

      case 'rejected':
        return const _StatusConfig(
          title: 'ไม่ผ่านการตรวจสอบ',
          description:
              'คำขอไม่ผ่านเงื่อนไขการตรวจสอบ กรุณาตรวจสอบรายละเอียดและดำเนินการตามที่ระบบแจ้ง',
          icon: Icons.cancel_outlined,
        );

      case 'requires_action':
        return const _StatusConfig(
          title: 'ต้องดำเนินการเพิ่มเติม',
          description:
              'ระบบต้องการข้อมูลหรือเอกสารเพิ่มเติมก่อนดำเนินการตรวจสอบต่อ',
          icon: Icons.edit_note_rounded,
        );

      default:
        return const _StatusConfig(
          title: 'ไม่ทราบสถานะ',
          description:
              'ระบบไม่สามารถระบุสถานะการตรวจสอบของคำขอนี้ได้',
          icon: Icons.help_outline_rounded,
        );
    }
  }
}

class _BusinessSummary extends StatelessWidget {
  const _BusinessSummary({
    required this.businessInformation,
  });

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'กิจการ',
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.storefront_outlined,
            label: 'ชื่อกิจการ',
            value: businessName,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.badge_outlined,
            label: 'เลขทะเบียน',
            value: registrationNumber,
          ),
        ],
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style:
                theme.textTheme.bodyMedium?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.config,
  });

  final String status;
  final _StatusConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            config.icon,
            color: config.foregroundColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'สถานะ',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color: theme
                        .colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.status,
    required this.onRetry,
    required this.onBackToKaoId,
    required this.onCompleted,
  });

  final String status;
  final VoidCallback onRetry;
  final VoidCallback onBackToKaoId;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'requires_action':
      case 'rejected':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: 'กลับไปดำเนินการ',
                icon: Icons.arrow_back_rounded,
                onPressed: onRetry,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onBackToKaoId,
              child: const Text('กลับสู่ Kao ID'),
            ),
          ],
        );

      case 'approved':
        return SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text: 'ดูข้อมูลกิจการ',
            icon: Icons.arrow_forward_rounded,
            onPressed: onCompleted,
          ),
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text: 'กลับสู่ Kao ID',
            icon: Icons.arrow_back_rounded,
            onPressed: onBackToKaoId,
          ),
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}