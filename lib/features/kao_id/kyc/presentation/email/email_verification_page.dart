import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/design_system/responsive/app_layout.dart';
import '../../../../../shared/design_system/responsive/app_page_layout.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/cards/app_card.dart';

import '../widgets/info_tile.dart';
import '../widgets/status_chip.dart';

final class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
  });

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

final class _EmailVerificationPageState
    extends State<EmailVerificationPage> {
  static const _title = 'ยืนยันอีเมล';

  static const _description =
      'ใช้อีเมลเพื่อเข้าสู่ระบบ รับการแจ้งเตือน '
      'และเพิ่มความปลอดภัยของบัญชี Kao ID';

  final _supabase = Supabase.instance.client;

  bool _sending = false;

  User? get _user => _supabase.auth.currentUser;

  Future<void> _sendVerification() async {
    final user = _user;

    if (user == null || user.email == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้งาน'),
        ),
      );

      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ส่งอีเมลยืนยันเรียบร้อยแล้ว',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final email = _user?.email ?? 'ไม่พบอีเมล';

    final verified =
        _user?.emailConfirmedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
      ),
      body: AppPageLayout(
        maxWidth: AppLayout.formMaxWidth,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                40,
              ),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _VerificationHeader(
                      title: _title,
                      description: _description,
                      verified: verified,
                    ),

                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        28,
                        28,
                        28,
                        32,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(
                            title: 'ข้อมูลอีเมล',
                            subtitle:
                                'ข้อมูลอีเมลที่ผูกกับบัญชี Kao ID',
                          ),

                          const SizedBox(height: 16),

                          InfoTile(
                            icon: Icons.email_outlined,
                            title: 'อีเมล',
                            value: email,
                          ),

                          const SizedBox(height: 12),

                          InfoTile(
                            icon:
                                Icons.verified_user_outlined,
                            title: 'สถานะ',
                            value: verified
                                ? 'ยืนยันแล้ว'
                                : 'ยังไม่ได้ยืนยัน',
                          ),

                          const SizedBox(height: 28),

                          if (!verified) ...[
                            PrimaryButton(
                              text: 'ส่งอีเมลยืนยัน',
                              icon: Icons.send_outlined,
                              isLoading: _sending,
                              onPressed:
                                  _sendVerification,
                            ),
                          ] else ...[
                            _VerifiedMessage(
                              colorScheme:
                                  colorScheme,
                            ),
                          ],

                          const SizedBox(height: 28),

                          _InformationCard(
                            colorScheme: colorScheme,
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _VerificationHeader
    extends StatelessWidget {
  const _VerificationHeader({
    required this.title,
    required this.description,
    required this.verified,
  });

  final String title;
  final String description;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accentColor = verified
        ? colorScheme.primary
        : colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        28,
        32,
        28,
        28,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.28),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
              verified
                  ? Icons.mark_email_read_outlined
                  : Icons.email_outlined,
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
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color:
                    colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 18),

          StatusChip(
            status:
                verified ? 'approved' : 'not_started',
          ),
        ],
      ),
    );
  }
}

final class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(
            color:
                colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _VerifiedMessage
    extends StatelessWidget {
  const _VerifiedMessage({
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer
            .withValues(alpha: 0.45),
        borderRadius:
            BorderRadius.circular(16),
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
            width: 36,
            height: 36,
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
                  'ยืนยันอีเมลแล้ว',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'อีเมลของคุณได้รับการยืนยันเรียบร้อยแล้ว',
                  style: Theme.of(context)
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
    );
  }
}

final class _InformationCard
    extends StatelessWidget {
  const _InformationCard({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
                      'สิ่งที่ควรรู้เกี่ยวกับการยืนยันอีเมล',
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
            icon: Icons.mark_email_read_outlined,
            text:
                'ลิงก์ยืนยันจะถูกส่งไปยังอีเมลของคุณ',
          ),

          const SizedBox(height: 12),

          const _InformationItem(
            icon: Icons.schedule_outlined,
            text:
                'ลิงก์มีอายุ 30 นาที',
          ),

          const SizedBox(height: 12),

          const _InformationItem(
            icon: Icons.sync_outlined,
            text:
                'หลังยืนยันแล้วสถานะจะเปลี่ยนอัตโนมัติ',
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