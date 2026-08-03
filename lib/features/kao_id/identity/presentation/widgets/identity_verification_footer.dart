import 'package:flutter/material.dart';

final class IdentityVerificationFooter extends StatelessWidget {
  const IdentityVerificationFooter({
    super.key,
    this.message =
        'หากมีข้อสงสัยเกี่ยวกับการยืนยันตัวตน กรุณาติดต่อทีมสนับสนุนของ Kao ID',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}