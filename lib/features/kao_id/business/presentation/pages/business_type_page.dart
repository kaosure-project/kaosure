import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessTypePage extends StatefulWidget {
  const BusinessTypePage({
    super.key,
  });

  static const routeName = '/kao-id/business/type';

  @override
  State<BusinessTypePage> createState() => _BusinessTypePageState();
}

class _BusinessTypePageState extends State<BusinessTypePage> {
  String? _selectedType;

  void _continue() {
    final selectedType = _selectedType;

    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกประเภทผู้ประกอบการ',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      '/kao-id/business/information',
      arguments: <String, dynamic>{
        'businessType': selectedType,
      },
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'ประเภทผู้ประกอบการ',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 760,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _StepHeader(
                        theme: theme,
                      ),

                      const SizedBox(height: 28),

                      _HeaderSection(
                        theme: theme,
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'เลือกประเภทที่ตรงกับกิจการของคุณ',
                        style:
                            theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'ข้อมูลที่คุณเลือกจะถูกนำไปใช้กำหนดข้อมูลและเอกสารที่ต้องใช้ในขั้นตอนถัดไป',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 18),

                      _BusinessTypeOption(
                        icon: Icons.storefront_outlined,
                        title:
                            'ผู้ประกอบการรายย่อย / ร้านค้าที่จดทะเบียน',
                        description:
                            'สำหรับร้านค้าและผู้ประกอบการที่มีทะเบียนการค้า หรือเอกสารรับรองการประกอบกิจการ',
                        value: 'registered_business',
                        groupValue: _selectedType,
                        onChanged: _selectType,
                      ),

                      const SizedBox(height: 14),

                      _BusinessTypeOption(
                        icon:
                            Icons.business_center_outlined,
                        title:
                            'ผู้ประกอบการที่มีเอกสารกิจการ',
                        description:
                            'สำหรับกิจการที่มีเอกสารประกอบการดำเนินธุรกิจตามประเภทที่ KaoSure รองรับ',
                        value: 'business_document',
                        groupValue: _selectedType,
                        onChanged: _selectType,
                      ),

                      const SizedBox(height: 28),

                      _SecurityNotice(
                        theme: theme,
                      ),

                      const SizedBox(height: 28),

                      PrimaryButton(
                        text: 'ดำเนินการต่อ',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _continue,
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: _goBack,
                          child: const Text(
                            'ย้อนกลับ',
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectType(String value) {
    setState(() {
      _selectedType = value;
    });
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '2',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'ประเภทผู้ประกอบการ',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ขั้นตอนที่ 2 จาก 6',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 2 / 6,
              minHeight: 6,
              backgroundColor:
                  colorScheme
                      .surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color:
                colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.category_outlined,
            size: 38,
            color:
                colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'คุณเป็นผู้ประกอบการประเภทใด?',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'เลือกประเภทกิจการเพื่อเริ่มกรอกข้อมูลธุรกิจ',
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyLarge?.copyWith(
            color:
                colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BusinessTypeOption extends StatelessWidget {
  const _BusinessTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = value == groupValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
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
                  color: selected
                      ? colorScheme.primary
                      : colorScheme
                          .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme
                          .onSurfaceVariant,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme
                          .textTheme.titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme
                          .textTheme.bodyMedium
                          ?.copyWith(
                        height: 1.45,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                selected
                    ? Icons
                        .radio_button_checked_rounded
                    : Icons
                        .radio_button_unchecked_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme
                        .onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme
            .surfaceContainerLowest,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลจะถูกตรวจสอบตามขั้นตอน',
                  style: theme
                      .textTheme.titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KaoSure จะใช้ประเภทกิจการที่เลือกเพื่อกำหนดข้อมูลและเอกสารที่จำเป็นสำหรับการตรวจสอบ',
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    height: 1.45,
                    color: colorScheme
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