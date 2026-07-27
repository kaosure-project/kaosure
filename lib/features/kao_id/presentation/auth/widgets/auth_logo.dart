import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_text_styles.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.showTitle = true,
    this.showSubtitle = true,
  });

  final bool showTitle;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.account_circle_rounded,
          size: 88,
        ),

        if (showTitle) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Kao ID',
            style: AppTextStyles.displaySmall,
            textAlign: TextAlign.center,
          ),
        ],

        if (showSubtitle) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ยินดีต้อนรับสู่ KaoSure',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}