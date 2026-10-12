import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sensitive_field.dart';
import '../../domain/repositories/personal_info_repository.dart';

class RevealState {
  const RevealState({this.revealed = const {}, this.loading = const {}, this.error});

  /// Full values currently on screen; each one hides itself after [RevealController.visibleFor].
  final Map<SensitiveField, String> revealed;
  final Set<SensitiveField> loading;
  final String? error;

  RevealState copyWith({Map<SensitiveField, String>? revealed, Set<SensitiveField>? loading,
    String? error, bool clearError = false}) => RevealState(
        revealed: revealed ?? this.revealed,
        loading: loading ?? this.loading,
        error: clearError ? null : error ?? this.error,
      );
}

class RevealController extends StateNotifier<RevealState> {
  RevealController(this._repository) : super(const RevealState());

  static const visibleFor = Duration(seconds: 30);

  final PersonalInfoRepository _repository;
  final Map<SensitiveField, Timer> _timers = {};
  RevealGrant? _grant;

  bool get needsPassword => !(_grant?.isActive ?? false);

  /// Returns null on success, otherwise the [PersonalInfoFailure.code].
  Future<String?> unlock(String password) async {
    state = state.copyWith(clearError: true);
    final previous = _grant;
    _grant = null;
    if (previous != null) unawaited(_repository.release(previous));
    try {
      final grant = await _repository.unlock(password);
      if (!mounted) {
        unawaited(_repository.release(grant));
        return 'session';
      }
      _grant = grant;
      return null;
    } on PersonalInfoFailure catch (failure) {
      return failure.code;
    }
  }

  Future<void> reveal(SensitiveField field) async {
    final grant = _grant;
    if (grant == null || !grant.isActive) {
      state = state.copyWith(error: 'password');
      return;
    }
    state = state.copyWith(loading: {...state.loading, field}, clearError: true);
    try {
      final value = await _repository.reveal(grant, field);
      if (!mounted) return;
      state = state.copyWith(revealed: {...state.revealed, field: value});
      _timers[field]?.cancel();
      _timers[field] = Timer(visibleFor, () => hide(field));
    } on PersonalInfoFailure catch (failure) {
      if (failure.code == 'password') _grant = null;
      if (mounted) state = state.copyWith(error: failure.code);
    } finally {
      if (mounted) state = state.copyWith(loading: {...state.loading}..remove(field));
    }
  }

  void hide(SensitiveField field) {
    _timers.remove(field)?.cancel();
    if (mounted) state = state.copyWith(revealed: {...state.revealed}..remove(field));
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    final grant = _grant;
    if (grant != null) unawaited(_repository.release(grant));
    super.dispose();
  }
}
