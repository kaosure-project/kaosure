import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            child: Icon(
              Icons.person,
              size: 48,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'พศวัต ถวิลคำ',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            'KID-00000001',
            style: AppTextStyles.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'ยืนยันอีเมลแล้ว',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'สมาชิกตั้งแต่ 20 กรกฎาคม 2569',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}