import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/profile_controller_provider.dart';
import '../widgets/kao_id_profile/card.dart';

final class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({
    super.key,
  });

  @override
  ConsumerState<AccountPage> createState() =>
      _AccountPageState();
}

final class _AccountPageState
    extends ConsumerState<AccountPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(profileControllerProvider.notifier)
          .loadCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      profileControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('บัญชีของฉัน'),
      ),
      body: SafeArea(
        child: _buildBody(
          context,
          state,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    dynamic state,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.errorMessage != null) {
      return _ErrorView(
        message: state.errorMessage!,
        onRetry: () {
          ref
              .read(
                profileControllerProvider.notifier,
              )
              .loadCurrentProfile();
        },
      );
    }

    if (state.profile == null) {
      return const _EmptyProfileView();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(
              profileControllerProvider.notifier,
            )
            .loadCurrentProfile();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          KaoIdProfileCard(
            profile: state.profile!,
          ),

          const SizedBox(height: 24),

          const _SectionHeader(
            title: 'บัญชีและความปลอดภัย',
          ),

          const SizedBox(height: 8),

          _AccountMenuCard(
            icon: Icons.verified_user_outlined,
            title: 'การยืนยันตัวตน',
            subtitle:
                'ยืนยันตัวตนเพื่อเพิ่มความปลอดภัยให้บัญชี',
            onTap: () {},
          ),

          _AccountMenuCard(
            icon: Icons.account_balance_outlined,
            title: 'บัญชีธนาคาร',
            subtitle:
                'จัดการบัญชีธนาคารสำหรับการรับเงิน',
            onTap: () {},
          ),

          _AccountMenuCard(
            icon: Icons.devices_outlined,
            title: 'อุปกรณ์',
            subtitle:
                'ตรวจสอบและจัดการอุปกรณ์ที่เข้าสู่ระบบ',
            onTap: () {},
          ),

          _AccountMenuCard(
            icon: Icons.lock_outline,
            title: 'เซสชันและการเข้าสู่ระบบ',
            subtitle:
                'ตรวจสอบกิจกรรมการเข้าสู่ระบบ',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          const _SectionHeader(
            title: 'บัญชีธุรกิจ',
          ),

          const SizedBox(height: 8),

          _AccountMenuCard(
            icon: Icons.business_outlined,
            title: 'บริษัท / องค์กร',
            subtitle:
                'จัดการองค์กรและสิทธิ์การเข้าถึง',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          const _SectionHeader(
            title: 'การตั้งค่า',
          ),

          const SizedBox(height: 8),

          _AccountMenuCard(
            icon: Icons.language_outlined,
            title: 'ภาษา',
            subtitle:
                'จัดการภาษาที่ใช้ใน Kao ID',
            onTap: () {},
          ),

          _AccountMenuCard(
            icon: Icons.notifications_none_outlined,
            title: 'การแจ้งเตือน',
            subtitle:
                'จัดการการแจ้งเตือนของ Kao ID',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

final class _AccountMenuCard extends StatelessWidget {
  const _AccountMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 3,
          ),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmptyProfileView extends StatelessWidget {
  const _EmptyProfileView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'ไม่พบข้อมูลโปรไฟล์',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}