import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kaosure/features/kao_id/governance/application/providers/owner_request_actions.dart';
import 'package:kaosure/features/kao_id/governance/data/repositories/supabase_owner_requests_repository.dart';
import 'package:kaosure/features/kao_id/governance/presentation/pages/owner_requests_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../widgets/admin_display.dart';

class OwnerRequestDetail extends ConsumerStatefulWidget {
  const OwnerRequestDetail({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  ConsumerState<OwnerRequestDetail> createState() => _OwnerRequestDetailState();
}

class _OwnerRequestDetailState extends ConsumerState<OwnerRequestDetail> {
  final _reason = TextEditingController();
  String? _owner;
  Map<String,dynamic>? _data;
  Object? _error;
  bool _busy = false;
  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;
  @override
  void initState() { super.initState(); _owner = ref.read(authProvider).asData?.value?.id; Future.microtask(_load); }
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  Future<void> _load() async {
    if (!_same || _busy) { return; }
    setState(() { _busy = true; _data = null; _error = null; });
    try { final data = await ref.read(ownerRequestsRepositoryProvider).checks(widget.row['id'] as String);
      if (_same) { setState(() => _data = data); }
    } catch(e) { if (_same) { setState(() => _error = e); } }
    finally { if (mounted) { setState(() => _busy = false); } }
  }
  Future<void> _reject({bool close = false}) async {
    if (!_same || _busy || _reason.text.trim().length < 3) { return; }
    final l = AppLocalizations.of(context);
    final reason = _reason.text.trim();
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: Text(close ? l.closeAccountAction : l.lifeReject), content: Consumer(builder: (context, ref, _) => SingleChildScrollView(child: Text(
        ref.watch(authProvider).asData?.value?.id == _owner ? (close ? '${l.closeAccountConfirm}\n\n$reason' : reason) : l.contactSessionChanged))),
      actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c,true), child: Text(l.continueLabel))]));
    if (yes != true || !_same) { return; }
    setState(() { _busy = true; _error = null; });
    try {
      if (close) {
        await ref.read(closeAccountActionProvider)(widget.row['id'] as String, reason);
      } else { await ref.read(ownerRequestsRepositoryProvider).reject(widget.row['id'] as String,reason); }
    }
    catch(e) { if (_same) { setState(() { _error = e; if (e is PostgrestException && e.code == '42501') { _data = null; } }); } }
    finally { if (mounted) { setState(() => _busy = false); } }
    if (_same && _error == null) { _reason.clear(); await _load(); }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final d = _data;
    final request = d?['request'] as Map?;
    return Scaffold(appBar: AppBar(title: Text(l.ownerRequests)), body: SafeArea(child: Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: !same
        ? Text(l.contactSessionChanged) : ListView(padding: const EdgeInsets.all(20), children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error is PostgrestException && (_error as PostgrestException).code == '42501' ? l.adminAccessDenied : l.reviewActionFailed),
          OutlinedButton(onPressed: _busy ? null : _load, child: Text(l.authCheckAgain)),
          if (d != null) ...[
            AdminSection(title: l.adminMembersTitle, children: [
              AdminValue(label: l.displayName,value: widget.row['display_name']),
              AdminValue(label: l.adminAccountCode,value: widget.row['account_code'],copyable:true),
              AdminValue(label: l.adminUserId,value: widget.row['profile_id'],copyable:true),
              AdminValue(label: l.kaoId,value: widget.row['kao_id']),
              AdminValue(label:l.lifeTitle,value:requestStatus(l,request?['status'] as String? ?? '')),
              AdminValue(label:l.reviewReason,value:request?['reason']),
            ]),
            AdminSection(title:l.lifeChecks,children:[
              Text(l.lifeChecksHelp),
              AdminValue(label:l.lifeOrders,value:d['orders_total']),
              AdminValue(label:l.lifeDisputes,value:d['disputes_total']),
              AdminValue(label:l.lifeKycPending,value:d['kyc_pending']),
              AdminValue(label:l.staffAssignments,value:d['staff_active']),
              for(final w in (d['wallets'] as List? ?? []).cast<Map>())
                AdminValue(label:'${l.lifeWallet} · ${realValue(w['currency'])}',value:'${realValue(w['balance'])} / ${realValue(w['hold_balance'])}'),
              if((d['wallets'] as List? ?? []).isEmpty) Text(l.lifeNoWallet),
              const SizedBox(height:12),
              if (request?['status'] == 'pending') Text(d['close_ready'] == true ? l.closeAccountReady : l.closeAccountBlocked),
              for (final b in (request?['status'] == 'pending' ? (d['blockers'] as List? ?? []) : []).cast<Map>())
                AdminValue(label: b['code'] == 'wallet_balance' ? l.lifeWallet :
                  b['code'] == 'account_state' ? l.closeAccountTitle : l.closeServiceReview,
                  value: '${realValue(b['table'])} · ${realValue(b['count'])}'),
            ]),
            if(request?['status']=='pending') AdminSection(title:l.lifeTitle,children:[
              TextField(controller:_reason,enabled:!_busy,maxLength:1000,maxLines:3,
                onChanged:(_) => setState(() {}),decoration:InputDecoration(labelText:l.reviewReason,border:const OutlineInputBorder())),
              FilledButton(onPressed:!_busy && _reason.text.trim().length>=3 ? () => _reject() : null,child:Text(l.lifeReject)),
              if (d['close_ready'] == true && request?['kind'] == 'closure')
                FilledButton.icon(key: const ValueKey('close-account'),
                  onPressed: !_busy && _reason.text.trim().length >= 3 ? () => _reject(close: true) : null,
                  icon: const Icon(Icons.lock_outline), label: Text(l.closeAccountAction)),
            ]),
            AdminSection(title:l.staffHistory,children:[
              if((d['history'] as List? ?? []).isEmpty) Text(l.staffEmpty),
              for(final h in (d['history'] as List? ?? []).cast<Map>()) ...[
                AdminValue(label:l.lifeTitle,value: switch(h['action']) {
                  'account.request.recover'=>l.recoveryRestored, 'account.request.close'=>l.closeAccountTitle, 'account.request.reject'=>l.lifeRejected,'account.request.cancel'=>l.lifeCancelled,
                  'account.request.closure'=>l.lifeClose,'account.request.recovery'=>l.lifeRecover,_=>l.kycUnknownStatus}),
                AdminValue(label:l.staffActor,value:'${realValue(h['actor_name_at_event'])}\n${realValue(h['actor_code'] ?? h['actor_id'])}',copyable:true),
                AdminValue(label:l.adminActorRole,value:adminRoles(l,h['actor_roles_at_event'])),
                if(['account.request.reject','account.request.close','account.request.recover'].contains(h['action'])) AdminValue(label:l.reviewReason,value:h['description']),
                Text(adminDate(context,h['created_at'])),const Divider(),
              ],
            ]),
          ],
        ])))));
  }
}
