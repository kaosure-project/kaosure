import 'package:flutter/foundation.dart';
import '../../domain/entities/contact_snapshot.dart';
import '../../domain/failures/contact_change_failure.dart';
import '../../domain/repositories/contact_change_repository.dart';

class ContactChangeController extends ChangeNotifier {
  ContactChangeController(this.repository, this.kind, {DateTime Function()? clock})
      : clock = clock ?? DateTime.now;
  final ContactChangeRepository repository;
  final ContactKind kind;
  final DateTime Function() clock;
  ContactSnapshot? snapshot;
  String pending = '';
  String? message;
  DateTime? retryAt;
  bool busy = false;
  bool known = false;
  bool _alive = true;
  String? _owner;
  bool get canSend => known && !busy &&
      (retryAt == null || !clock().isBefore(retryAt!));

  void _emit() { if (_alive) notifyListeners(); }
  void _accept(ContactSnapshot next) {
    if (_owner != null && next.owner != _owner) {
      snapshot = null;
      pending = '';
      known = false;
      throw const ContactChangeFailure('session');
    }
    _owner = next.owner;
    snapshot = next;
    known = true;
    if (pending.isNotEmpty && next.confirmed && next.value == pending) {
      pending = '';
      message = 'done';
    } else if (next.pending.isNotEmpty) {
      pending = next.pending;
    } else if (pending.isNotEmpty) {
      message = 'pending';
    }
  }

  Future<void> refresh() async {
    if (!_alive || busy) { return; }
    busy = true;
    message = null;
    _emit();
    try {
      final next = await repository.read(kind);
      if (!_alive) { return; }
      _accept(next);
    } catch (error) {
      if (!_alive) { return; }
      known = false;
      message = error is ContactChangeFailure ? error.code : 'load';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> submit(String input, String password,
      {String? factorId, String? code}) async {
    if (!_alive || !canSend) { return; }
    final target = normalizeContact(kind, input);
    if (target == null || target == snapshot?.value) {
      message = target == null ? 'invalid' : 'same';
      _emit();
      return;
    }
    if (password.isEmpty) {
      message = 'password';
      _emit();
      return;
    }
    busy = true;
    message = null;
    retryAt = clock().add(const Duration(seconds: 60));
    _emit();
    try {
      final before = await repository.read(kind);
      if (!_alive) { return; }
      _accept(before);
      await repository.request(kind, before.owner, target, password,
        resend: pending == target, factorId: factorId, code: code);
      if (!_alive) { return; }
      pending = target;
      message = 'sent';
      // The request response is not proof that the new destination is verified.
      final after = await repository.read(kind);
      if (!_alive) { return; }
      _accept(after);
    } catch (error) {
      if (!_alive) { return; }
      message = error is ContactChangeFailure ? error.code : 'request';
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> verify(String token) async {
    if (!_alive || busy || !known || pending.isEmpty || kind != ContactKind.phone) { return; }
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(token.trim())) {
      message = 'otp';
      _emit();
      return;
    }
    busy = true;
    message = null;
    _emit();
    try {
      await repository.verifyPhone(_owner!, pending, token.trim());
      final next = await repository.read(kind);
      if (!_alive) { return; }
      _accept(next);
    } catch (error) {
      if (!_alive) { return; }
      message = error is ContactChangeFailure ? error.code : 'verify';
    } finally {
      busy = false;
      _emit();
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }
}
