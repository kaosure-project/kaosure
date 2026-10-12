import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/notifications/application/providers/notice_inbox_provider.dart';
import 'package:kaosure/features/kao_id/notifications/presentation/pages/notification_center_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key, this.compact = false});

  /// Shows an icon with an unread badge instead of a labelled button.
  final bool compact;
  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) { ref.invalidate(noticeInboxProvider); }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { ref.invalidate(noticeInboxProvider); }
  }
  @override
  void dispose() { _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(noticeInboxProvider);
    final count = state.asData?.value['unread'] ?? 0;
    Future<void> open() async {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NotificationCenter()));
      if (mounted) { ref.invalidate(noticeInboxProvider); }
    }
    if (widget.compact) {
      return IconButton(
        tooltip: l.noticeTitle,
        onPressed: open,
        icon: Badge(
          isLabelVisible: state.hasError || count != 0,
          label: Text(state.hasError ? '!' : count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_outlined),
        ),
      );
    }
    return OutlinedButton.icon(icon: const Icon(Icons.notifications_outlined),
      label: Text('${l.noticeTitle}${state.hasError ? ' · !' : count == 0 ? '' : ' ($count)'}'),
      onPressed: open);
  }
}
