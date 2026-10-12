import 'package:supabase_flutter/supabase_flutter.dart';
import '../../kao_id/account/presentation/pages/security/mfa_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../../kao_id/account/data/repositories/supabase_account_access_repository.dart';
import '../../kao_id/governance/presentation/widgets/admin_display.dart';
import 'partner_repository.dart';

String partnerLabel(AppLocalizations l,String code) => switch(code) {
  'sandbox'=>l.partnerSandbox,'live'=>l.partnerLive,
  'pending'=>l.partnerPending,'approved'=>l.partnerApproved,'rejected'=>l.partnerRejected,'disabled'=>l.partnerDisabled,
  'approve'=>l.partnerApprove,'reject'=>l.partnerReject,'disable'=>l.partnerDisable,'resubmit'=>l.partnerResubmit,'enable'=>l.partnerEnable,
  'balance'=>l.partnerBalance,'payment'=>l.partnerPayment,'refund'=>l.partnerRefund,'payout'=>l.partnerPayout,'topup'=>l.partnerTopup,
  'quote'=>l.carrierQuote,'shipment'=>l.carrierShipment,'tracking'=>l.carrierTracking,'cancel_shipment'=>l.carrierCancel,
  'create'=>l.partnerAdd,'readiness'=>l.partnerReadiness,_=>code,
};
class PartnerPage extends ConsumerStatefulWidget {
  const PartnerPage({super.key,this.shipping=false});
  final bool shipping;
  @override
  ConsumerState<PartnerPage> createState()=>_PartnerPageState();
}
class _PartnerPageState extends ConsumerState<PartnerPage> with WidgetsBindingObserver {
  List<Map<String,dynamic>> _rows=[];
  bool _busy=true,_failed=false,_mfaRequired=false;
  String? _user;
  int _generation=0;
  StreamSubscription<void>? _subscription;
  PartnerRepository get _repository => ref.read(widget.shipping ? shippingPartnerRepositoryProvider : partnerRepositoryProvider);
  bool get _same=>_user!=null && ref.read(accountAccessRepositoryProvider).userId==_user;
  @override
  void initState(){
    super.initState();WidgetsBinding.instance.addObserver(this);
    _user=ref.read(accountAccessRepositoryProvider).userId;
    _subscription=ref.read(accountAccessRepositoryProvider).changes.listen((_) {
      if(!mounted) {return;}
      if(!_same){_generation++;setState((){_rows=[];_busy=false;});}
      else {unawaited(_load());}
    });
    unawaited(_load());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s){if(s==AppLifecycleState.resumed && _same) {unawaited(_load());}}
  Future<void> _load() async {
    if(!_same){if(mounted) {setState(()=>_busy=false);}return;}
    final g=++_generation;
    setState((){_busy=true;_failed=false;_mfaRequired=false;_rows=[];});
    try {
      final rows=await _repository.list(_user!);
      if(mounted && _same && g==_generation) {setState(()=>_rows=rows.where((r)=>(r['kind']??'finance')==(widget.shipping?'shipping':'finance')).toList());}
    }catch(_){if(mounted && _same && g==_generation) {setState(()=>_failed=true);}}
    finally{if(mounted && g==_generation) {setState(()=>_busy=false);}}
  }
  Future<void> _save(Future<void> Function() call) async {
    if(!_same || _busy) {return;}
    setState(()=>_busy=true);
    try {await call();if(mounted && _same) {await _load();}}
    catch(e){if(mounted && _same) {setState((){_failed=true;_mfaRequired=e is PostgrestException && e.message=='mfa_required';_rows=[];_busy=false;});}}
  }
  Future<void> _add() async {
    final draft=await showDialog<_PartnerDraft>(context:context,builder:(_)=>_PartnerForm(shipping:widget.shipping));
    if(!mounted || !_same || draft==null) {return;}
    await _save(()=>_repository.create(_user!,draft.code,draft.name,draft.environment,draft.capabilities));
  }
  Future<void> _decide(Map<String,dynamic> row,String action) async {
    final l=AppLocalizations.of(context);
    final reason=await showDialog<String>(context:context,builder:(_)=>_DecisionDialog(
      title:partnerLabel(l,action),name:'${realValue(row['name'])} · ${partnerLabel(l,row['environment'] as String)}'));
    if(!mounted || !_same || reason==null) {return;}
    await _save(()=>_repository.decide(_user!,row['id'] as String,row['revision'] as int,action,reason));
  }
  @override
  void dispose(){_generation++;_subscription?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override
  Widget build(BuildContext context){
    final l=AppLocalizations.of(context);
    return Scaffold(appBar:AppBar(title:Text(widget.shipping?l.carrierTitle:l.partnerTitle)),body:SafeArea(child:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:900),child:ListView(padding:const EdgeInsets.all(20),children:[
        Text(l.partnerHelp),const SizedBox(height:16),
        if(!_same) Text(l.contactSessionChanged)
        else if(_busy) const LinearProgressIndicator()
        else if(_failed) ...[Text(_mfaRequired ? l.mfaSessionRequired : l.partnerFailed),OutlinedButton(onPressed:_load,child:Text(l.retry)),
          if(_mfaRequired) TextButton(onPressed:() async {await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>const MfaPage()));if(mounted && _same){await _load();}},child:Text(l.twoFactorAuthentication))]
        else ...[
          Wrap(spacing:12,runSpacing:8,children:[FilledButton.icon(onPressed:_add,icon:const Icon(Icons.add),label:Text(l.partnerAdd)),
            TextButton.icon(onPressed:_load,icon:const Icon(Icons.refresh),label:Text(l.authCheckAgain))]),
          if(_rows.isEmpty) Padding(padding:const EdgeInsets.all(24),child:Text(l.partnerEmpty)),
          for(final row in _rows) Card(margin:const EdgeInsets.symmetric(vertical:10),child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text(realValue(row['name']),style:Theme.of(context).textTheme.titleLarge),
            SelectableText(realValue(row['code'])),
            Wrap(spacing:8,children:[Chip(label:Text(partnerLabel(l,row['environment'] as String))),Chip(label:Text(partnerLabel(l,row['approval'] as String)))]),
            Text(row['connected']==true?l.partnerConnected:l.partnerNotConnected),
            Text(row['ready']==true?l.partnerReady:l.partnerNotReady),
            const SizedBox(height:8),Text(l.partnerCapabilities),
            Wrap(spacing:8,children:[for(final c in row['capabilities'] as List) Chip(label:Text(partnerLabel(l,c as String)))]),
            if(row['readiness'] is Map) ...[
              SelectableText('${l.partnerReadiness}: ${realValue(row['readiness']['adapter_version'])}'),
              Text('${l.partnerExpires}: ${adminDate(context,row['readiness']['expires_at'])}'),
            ],
            const SizedBox(height:12),
            Wrap(spacing:12,runSpacing:8,children:[
              if(row['approval']=='pending') ...[
                FilledButton(onPressed:()=>_decide(row,'approve'),child:Text(l.partnerApprove)),
                OutlinedButton(onPressed:()=>_decide(row,'reject'),child:Text(l.partnerReject)),
              ],
              if(row['approval']=='approved') ...[
                if(row['enabled']!=true) FilledButton(onPressed:row['ready']==true?()=>_decide(row,'enable'):null,child:Text(l.partnerEnable)),
                OutlinedButton(onPressed:()=>_decide(row,'disable'),child:Text(l.partnerDisable)),
              ],
              if(row['approval']=='disabled' || row['approval']=='rejected') OutlinedButton(onPressed:()=>_decide(row,'resubmit'),child:Text(l.partnerResubmit)),
            ]),
            ExpansionTile(title:Text(l.partnerHistory),children:[
              for(final raw in row['history'] as List) ListTile(
                title:Text(partnerLabel(l,raw['action'] as String)),
                subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(adminDate(context,raw['created_at'])),
                  Text('${l.partnerActor}: ${raw['actor_role']=='system'?l.partnerSystem:realValue(raw['actor_role'])}'),
                  if(raw['actor_id']!=null) SelectableText(realValue(raw['actor_id'])),
                  Text(realValue(raw['reason'])),
                ])),
            ]),
          ]))),
        ],
      ])))));
  }
}
class _PartnerDraft {
  _PartnerDraft(this.code,this.name,this.environment,this.capabilities);
  final String code,name,environment;
  final List<String> capabilities;
}
class _PartnerForm extends StatefulWidget {
  const _PartnerForm({required this.shipping});
  final bool shipping;
  @override
  State<_PartnerForm> createState()=>_PartnerFormState();
}
class _PartnerFormState extends State<_PartnerForm> {
  final _code=TextEditingController(),_name=TextEditingController();
  String _environment='sandbox';final _caps=<String>{};
  bool get _valid=>RegExp(r'^[a-z][a-z0-9_-]{1,39}$').hasMatch(_code.text.trim()) && _name.text.trim().length>=2 && _caps.isNotEmpty;
  @override
  void dispose(){_code.dispose();_name.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){final l=AppLocalizations.of(context);return AlertDialog(title:Text(l.partnerAdd),content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(l.partnerFormHelp),
    TextField(controller:_code,maxLength:40,decoration:InputDecoration(labelText:l.partnerCode),onChanged:(_)=>setState((){})),
    TextField(controller:_name,maxLength:120,decoration:InputDecoration(labelText:l.partnerName),onChanged:(_)=>setState((){})),
    DropdownButton<String>(value:_environment,isExpanded:true,items:[for(final mode in ['sandbox','live']) DropdownMenuItem(value:mode,child:Text(partnerLabel(l,mode)))],onChanged:(v){if(v!=null) {setState(()=>_environment=v);}}),
    Text(l.partnerCapabilities),
    for(final cap in (widget.shipping?['quote','shipment','tracking','cancel_shipment']:['balance','payment','refund','payout','topup'])) CheckboxListTile(contentPadding:EdgeInsets.zero,title:Text(partnerLabel(l,cap)),value:_caps.contains(cap),onChanged:(v)=>setState((){if(v==true){_caps.add(cap);}else{_caps.remove(cap);}})),
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l.cancel)),FilledButton(onPressed:_valid?()=>Navigator.pop(context,_PartnerDraft(_code.text.trim(),_name.text.trim(),_environment,_caps.toList())):null,child:Text(l.partnerAdd))]);}
}
class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog({required this.title,required this.name});
  final String title,name;
  @override
  State<_DecisionDialog> createState()=>_DecisionDialogState();
}
class _DecisionDialogState extends State<_DecisionDialog>{
  final _reason=TextEditingController();
  @override
  void dispose(){_reason.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){final l=AppLocalizations.of(context);return AlertDialog(title:Text(widget.title),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(widget.name),Text(l.partnerConfirm),TextField(controller:_reason,maxLength:500,decoration:InputDecoration(labelText:l.partnerReason),onChanged:(_)=>setState((){})),
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l.cancel)),FilledButton(onPressed:_reason.text.trim().length>=3?()=>Navigator.pop(context,_reason.text.trim()):null,child:Text(l.continueLabel))]);}
}
