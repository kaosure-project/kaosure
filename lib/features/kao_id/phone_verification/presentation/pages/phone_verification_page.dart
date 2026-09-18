import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/phone_verification_provider.dart';

final class PhoneVerificationPage
    extends ConsumerStatefulWidget {
  const PhoneVerificationPage({
    super.key,
  });

  @override
  ConsumerState<PhoneVerificationPage> createState() =>
      _PhoneVerificationPageState();
}

final class _PhoneVerificationPageState
    extends ConsumerState<PhoneVerificationPage> {
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();

    final state = ref.read(
      phoneVerificationControllerProvider,
    );

    _phoneController = TextEditingController(
      text: state.phoneNumber,
    );

    _otpController = TextEditingController();

    Future.microtask(() {
      ref
          .read(
            phoneVerificationControllerProvider
                .notifier,
          )
          .load();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      phoneVerificationControllerProvider,
    );

    ref.listen(
      phoneVerificationControllerProvider,
      (previous, next) {
        if (next.errorMessage != null &&
            next.errorMessage !=
                previous?.errorMessage) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  next.errorMessage!,
                ),
                behavior:
                    SnackBarBehavior.floating,
              ),
            );
        }

        if (next.isVerified &&
            previous?.isVerified != true) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'ยืนยันเบอร์โทรศัพท์สำเร็จ',
                ),
                behavior:
                    SnackBarBehavior.floating,
              ),
            );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ยืนยันเบอร์โทรศัพท์',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final horizontalPadding =
                constraints.maxWidth >= 900
                    ? 32.0
                    : 20.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                ),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    40,
                  ),
                  children: [
                    _PhoneVerificationHeader(
                      isVerified: state.isVerified,
                      isOtpSent: state.isOtpSent,
                    ),

                    const SizedBox(height: 24),

                    _PhoneNumberSection(
                      controller: _phoneController,
                      isVerified: state.isVerified,
                      isLoading: state.isLoading,
                      isOtpSent: state.isOtpSent,
                    ),

                    const SizedBox(height: 16),

                    _VerificationStatusCard(
                      isVerified: state.isVerified,
                      isOtpSent: state.isOtpSent,
                    ),

                    if (state.isOtpSent &&
                        !state.isVerified) ...[
                      const SizedBox(height: 24),

                      _OtpSection(
                        controller: _otpController,
                        isLoading: state.isLoading,
                        onVerify: () async {
                          await ref
                              .read(
                                phoneVerificationControllerProvider
                                    .notifier,
                              )
                              .verifyOtp(
                                otp:
                                    _otpController.text,
                              );
                        },
                        onChangePhone: () {
                          _otpController.clear();

                          ref
                              .read(
                                phoneVerificationControllerProvider
                                    .notifier,
                              )
                              .clearOtp();
                        },
                      ),
                    ] else if (!state.isVerified) ...[
                      const SizedBox(height: 24),

                      _SendOtpButton(
                        isLoading: state.isLoading,
                        onPressed: () async {
                          await ref
                              .read(
                                phoneVerificationControllerProvider
                                    .notifier,
                              )
                              .sendOtp(
                                phoneNumber:
                                    _phoneController.text,
                              );
                        },
                      ),
                    ],

                    if (state.isVerified) ...[
                      const SizedBox(height: 24),

                      const _VerifiedMessage(),
                    ],

                    const SizedBox(height: 24),

                    const _InformationCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _PhoneVerificationHeader
    extends StatelessWidget {
  const _PhoneVerificationHeader({
    required this.isVerified,
    required this.isOtpSent,
  });

  final bool isVerified;
  final bool isOtpSent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accentColor = isVerified
        ? colorScheme.primary
        : isOtpSent
            ? colorScheme.secondary
            : colorScheme.primary;

    final icon = isVerified
        ? Icons.verified_outlined
        : isOtpSent
            ? Icons.sms_outlined
            : Icons.phone_android_outlined;

    final title = isVerified
        ? 'ยืนยันเบอร์โทรศัพท์แล้ว'
        : 'ยืนยันเบอร์โทรศัพท์';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          28,
          32,
          28,
          28,
        ),
        decoration: BoxDecoration(
          color: colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.28),
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: accentColor.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 38,
                color: accentColor,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 600,
              ),
              child: Text(
                'ใช้สำหรับยืนยันความเป็นเจ้าของหมายเลขโทรศัพท์ '
                'เพื่อเพิ่มความปลอดภัยของบัญชีและรองรับ '
                'การยืนยันตัวตนด้วย OTP',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: colorScheme
                      .onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 18),

            _PhoneStatusChip(
              isVerified: isVerified,
              isOtpSent: isOtpSent,
            ),
          ],
        ),
      ),
    );
  }
}

final class _PhoneStatusChip
    extends StatelessWidget {
  const _PhoneStatusChip({
    required this.isVerified,
    required this.isOtpSent,
  });

  final bool isVerified;
  final bool isOtpSent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color color;
    final IconData icon;
    final String label;

    if (isVerified) {
      color = colorScheme.primary;
      icon = Icons.check_circle_outline;
      label = 'ยืนยันแล้ว';
    } else if (isOtpSent) {
      color = colorScheme.secondary;
      icon = Icons.sms_outlined;
      label = 'รอยืนยัน OTP';
    } else {
      color = colorScheme.onSurfaceVariant;
      icon = Icons.phone_outlined;
      label = 'ยังไม่ได้ยืนยัน';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final class _PhoneNumberSection
    extends StatelessWidget {
  const _PhoneNumberSection({
    required this.controller,
    required this.isVerified,
    required this.isLoading,
    required this.isOtpSent,
  });

  final TextEditingController controller;
  final bool isVerified;
  final bool isLoading;
  final bool isOtpSent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'หมายเลขโทรศัพท์',
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'หมายเลขที่ผูกกับบัญชี Kao ID',
              style: theme.textTheme.bodySmall
                  ?.copyWith(
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: controller,
              enabled: !isVerified &&
                  !isLoading &&
                  !isOtpSent,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                prefixIcon: Icon(
                  Icons.phone_outlined,
                ),
                labelText:
                    'เบอร์โทรศัพท์',
                hintText:
                    '+66812345678',
                border:
                    OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _VerificationStatusCard
    extends StatelessWidget {
  const _VerificationStatusCard({
    required this.isVerified,
    required this.isOtpSent,
  });

  final bool isVerified;
  final bool isOtpSent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final IconData icon;
    final Color color;
    final String title;
    final String description;

    if (isVerified) {
      icon = Icons.verified_outlined;
      color = colorScheme.primary;
      title = 'ยืนยันแล้ว';
      description =
          'หมายเลขโทรศัพท์ได้รับการยืนยันแล้ว';
    } else if (isOtpSent) {
      icon = Icons.sms_outlined;
      color = colorScheme.secondary;
      title = 'ส่งรหัส OTP แล้ว';
      description =
          'กรุณากรอกรหัส OTP ที่ได้รับเพื่อดำเนินการต่อ';
    } else {
      icon = Icons.info_outline;
      color = colorScheme.onSurfaceVariant;
      title = 'ยังไม่ได้ยืนยัน';
      description =
          'กรุณากรอกหมายเลขโทรศัพท์และส่งรหัส OTP';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color.withValues(
        alpha: 0.06,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 21,
                color: color,
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
                        .titleSmall
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: colorScheme
                          .onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _OtpSection
    extends StatelessWidget {
  const _OtpSection({
    required this.controller,
    required this.isLoading,
    required this.onVerify,
    required this.onChangePhone,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme
                        .secondaryContainer,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 21,
                    color: colorScheme
                        .onSecondaryContainer,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'กรอกรหัส OTP',
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'กรอกรหัส 6 หลักที่ได้รับทาง SMS',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: controller,
              enabled: !isLoading,
              keyboardType:
                  TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'รหัส OTP',
                hintText: '000000',
                prefixIcon: Icon(
                  Icons.password_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            FilledButton.icon(
              onPressed:
                  isLoading ? null : onVerify,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.verified_outlined,
                    ),
              label: Text(
                isLoading
                    ? 'กำลังตรวจสอบ...'
                    : 'ยืนยัน OTP',
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed:
                  isLoading ? null : onChangePhone,
              child: const Text(
                'เปลี่ยนหมายเลขโทรศัพท์',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SendOtpButton
    extends StatelessWidget {
  const _SendOtpButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed:
          isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.sms_outlined,
            ),
      label: Text(
        isLoading
            ? 'กำลังส่ง OTP...'
            : 'ส่งรหัส OTP',
      ),
    );
  }
}

final class _VerifiedMessage
    extends StatelessWidget {
  const _VerifiedMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.45),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary
              .withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 20,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'ยืนยันเบอร์โทรศัพท์แล้ว',
                  style: theme.textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'หมายเลขโทรศัพท์ของคุณได้รับการยืนยันแล้ว',
                  style: theme.textTheme
                      .bodySmall
                      ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
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
}

final class _InformationCard
    extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      colorScheme.secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme
                      .onSecondaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อมูลเพิ่มเติม',
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ข้อควรระวังในการยืนยันหมายเลขโทรศัพท์',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],

          ),

          const SizedBox(height: 18),

          const _InformationItem(
            icon: Icons.sms_outlined,
            text:
                'รหัส OTP จะถูกส่งไปยังหมายเลขโทรศัพท์ที่คุณระบุ',
          ),

          const SizedBox(height: 12),

          const _InformationItem(
            icon: Icons.lock_outline,
            text:
                'ห้ามเปิดเผยรหัส OTP ให้ผู้อื่น',
          ),

          const SizedBox(height: 12),

          const _InformationItem(
            icon: Icons.sync_outlined,
            text:
                'หลังจากยืนยันสำเร็จ สถานะบัญชีจะได้รับการอัปเดตอัตโนมัติ',
          ),
        ],
      ),
    );
  }
}

final class _InformationItem
    extends StatelessWidget {
  const _InformationItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: colorScheme.primary,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall
                ?.copyWith(
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}