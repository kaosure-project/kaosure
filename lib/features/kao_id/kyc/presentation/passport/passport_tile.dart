import 'package:flutter/material.dart';

final class PassportTile extends StatelessWidget {
  const PassportTile({
    super.key,
    required this.status,
    required this.expiryDate,
    required this.onTap,
  });

  final String status;
  final DateTime? expiryDate;
  final VoidCallback onTap;

  bool get _isVerified =>
      status == 'verified' ||
      status == 'approved';

  bool get _isPending =>
      status == 'pending';

  bool get _isRejected =>
      status == 'rejected';

  bool get _isExpired =>
      status == 'expired';

  Color _statusColor(
    ColorScheme colorScheme,
  ) {
    if (_isVerified) {
      return Colors.green;
    }

    if (_isPending) {
      return Colors.orange;
    }

    if (_isRejected || _isExpired) {
      return colorScheme.error;
    }

    return colorScheme.onSurfaceVariant;
  }

  IconData _statusIcon() {
    if (_isVerified) {
      return Icons.check_circle_outline;
    }

    if (_isPending) {
      return Icons.hourglass_top_outlined;
    }

    if (_isRejected) {
      return Icons.error_outline;
    }

    if (_isExpired) {
      return Icons.event_busy_outlined;
    }

    return Icons.remove_circle_outline;
  }

  String _statusText() {
    if (_isVerified) {
      return 'ยืนยันแล้ว';
    }

    if (_isPending) {
      return 'กำลังตรวจสอบ';
    }

    if (_isRejected) {
      return 'ไม่ผ่าน';
    }

    if (_isExpired) {
      return 'หมดอายุ';
    }

    return 'ยังไม่ได้เพิ่ม';
  }

  String _expiryText() {
    final date = expiryDate;

    if (date == null) {
      return 'ยังไม่ได้ระบุวันหมดอายุ';
    }

    return 'หมดอายุ '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final statusColor = _statusColor(colors);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // ============================================================
              // ICON
              // ============================================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // ============================================================
              // TITLE + EXPIRY
              // ============================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'หนังสือเดินทาง',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _expiryText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ============================================================
              // STATUS
              // ============================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusText(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      _statusIcon(),
                      size: 14,
                      color: statusColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ============================================================
              // CHEVRON
              // ============================================================

              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}