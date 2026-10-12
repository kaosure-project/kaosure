import 'dart:async';
import 'package:flutter/material.dart';

/// UI refresh only. Every protected operation still authorizes on the server.
mixin AccessRefresh<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Timer? _accessTimer;
  void refreshAccess();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { refreshAccess(); }
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) { refreshAccess(); }
  }
  @override
  void dispose() {
    _accessTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
