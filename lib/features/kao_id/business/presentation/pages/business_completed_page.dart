import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessCompletedPage extends StatelessWidget {
  const BusinessCompletedPage({
    super.key,
    required this.businessInformation,
  });

  static const routeName =
      '/kao-id/business/completed';

  final Map<String, dynamic> businessInformation;

  String _value(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    return text.isEmpty ? '-' : text;
  }

  void _backToKaoId(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final businessName = _value(
      businessInformation['business_name'],
    );

    final registrationNumber = _value(
      businessInformation['registration_number'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('สมัครผู้ประกอบการ'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),

              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    size: 48,
                    color: theme.colorScheme
                        .onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'การสมัครเสร็จสมบูรณ์',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'ข้อมูลผู้ประกอบการได้รับการยืนยันแล้ว '
                'และพร้อมใช้งานตามสิทธิ์ของบัญชี',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 32),

              _BusinessSummaryCard(
                businessName: businessName,
                registrationNumber:
                    registrationNumber,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color:
                          theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'บัญชีของคุณยังคงเป็น Kao ID เดิม '
                        'และข้อมูลกิจการจะถูกใช้เป็น '
                        'Organization สำหรับสิทธิ์ทางธุรกิจ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: 'กลับสู่ Kao ID',
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    _backToKaoId(context),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({
    required this.businessName,
    required this.registrationNumber,
  });

  final String businessName;
  final String registrationNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
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
            'ข้อมูลกิจการ',
            style: theme.textTheme.titleMedium
                ?.copyWith(
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
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              color: theme.colorScheme
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}