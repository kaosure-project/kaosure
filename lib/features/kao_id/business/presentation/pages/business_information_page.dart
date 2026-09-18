import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/buttons/primary_button.dart';

class BusinessInformationPage extends StatefulWidget {
  const BusinessInformationPage({
    super.key,
  });

  static const routeName =
      '/kao-id/business/information';

  @override
  State<BusinessInformationPage> createState() =>
      _BusinessInformationPageState();
}

class _BusinessInformationPageState
    extends State<BusinessInformationPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController =
      TextEditingController();

  final _registrationNumberController =
      TextEditingController();

  String? _businessType;
  String _countryCode = 'TH';

  static const _businessTypes = <String>[
    'ผู้ประกอบการรายย่อย / ทะเบียนการค้า',
    'บริษัท',
    'นิติบุคคล',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final businessInformation =
        <String, dynamic>{
      'business_name':
          _businessNameController.text.trim(),
      'registration_number':
          _registrationNumberController.text.trim(),
      'business_type': _businessType,
      'country_code': _countryCode,
    };

    Navigator.of(context).pushNamed(
      '/kao-id/business/document',
      arguments: businessInformation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลกิจการ'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อมูลกิจการ',
                  style:
                      theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'กรอกข้อมูลกิจการให้ตรงกับเอกสาร '
                  'ที่จะใช้ยืนยันในขั้นตอนถัดไป',
                  style:
                      theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: theme
                        .colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 28),

                TextFormField(
                  controller:
                      _businessNameController,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      const InputDecoration(
                    labelText: 'ชื่อกิจการ',
                    hintText:
                        'กรอกชื่อร้านหรือชื่อกิจการ',
                    prefixIcon: Icon(
                      Icons.storefront_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text =
                        value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'กรุณากรอกชื่อกิจการ';
                    }

                    if (text.length < 2) {
                      return 'ชื่อกิจการต้องมีอย่างน้อย 2 ตัวอักษร';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: _businessType,
                  decoration:
                      const InputDecoration(
                    labelText: 'ประเภทกิจการ',
                    prefixIcon: Icon(
                      Icons.business_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: _businessTypes
                      .map(
                        (type) =>
                            DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _businessType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'กรุณาเลือกประเภทกิจการ';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller:
                      _registrationNumberController,
                  textInputAction:
                      TextInputAction.done,
                  decoration:
                      const InputDecoration(
                    labelText: 'เลขทะเบียน',
                    hintText:
                        'เลขทะเบียนการค้า / เลขทะเบียนบริษัท / เลขนิติบุคคล',
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text =
                        value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'กรุณากรอกเลขทะเบียน';
                    }

                    if (text.length < 5) {
                      return 'กรุณาตรวจสอบเลขทะเบียน';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: _countryCode,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'ประเทศที่จดทะเบียน',
                    prefixIcon: Icon(
                      Icons.public_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TH',
                      child: Text('ประเทศไทย'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _countryCode = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(16),
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
                        color: theme
                            .colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ข้อมูลนี้จะถูกใช้ร่วมกับเอกสารกิจการ '
                          'และกระบวนการตรวจสอบ Organization '
                          'ของ Kao ID',
                          style: theme
                              .textTheme.bodyMedium
                              ?.copyWith(
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
                    text: 'ดำเนินการต่อ',
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
                    child: const Text('ย้อนกลับ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}