import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/core/providers/supabase_provider.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import '../kao_id/account/data/repositories/supabase_account_access_repository.dart';
import '../kao_id/governance/presentation/widgets/admin_display.dart';
abstract class LinkedWalletRepository {
  Future<List<Map<String,dynamic>>> load(String user,String? profile);
}
final linkedWalletRepositoryProvider=Provider<LinkedWalletRepository>((ref)=>_LinkedWalletRepository(ref));
class _LinkedWalletRepository implements LinkedWalletRepository {
  _LinkedWalletRepository(this.ref);final Ref ref;
  @override
  Future<List<Map<String,dynamic>>> load(String user,String? profile) async =>
    (await ref.read(supabaseClientProvider).rpc('linked_wallets_r12c',params:{'p_user':user,'p_profile':profile}) as List).map((r)=>Map<String,dynamic>.from(r as Map)).toList();
}
class LinkedWalletsPage extends ConsumerStatefulWidget {
  const LinkedWalletsPage({super.key,this.profile});final String? profile;
  @override
  ConsumerState<LinkedWalletsPage> createState()=>_LinkedWalletsPageState();
}
class _LinkedWalletsPageState extends ConsumerState<LinkedWalletsPage> with WidgetsBindingObserver {
  List<Map<String,dynamic>> _rows=[];bool _busy=true,_failed=false;String? _user;int _generation=0;StreamSubscription<void>? _subscription;
  bool get _same=>_user!=null && ref.read(accountAccessRepositoryProvider).userId==_user;
  @override
  void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_user=ref.read(accountAccessRepositoryProvider).userId;
    _subscription=ref.read(accountAccessRepositoryProvider).changes.listen((_){if(!mounted) {return;}if(!_same){_generation++;setState((){_rows=[];_busy=false;});}else{unawaited(_load());}});unawaited(_load());}
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed && _same) {unawaited(_load());}}
  Future<void> _load() async {
    final g=++_generation;if(!_same){if(mounted) {setState(()=>_busy=false);}return;}
    setState((){_busy=true;_failed=false;_rows=[];});
    try{final rows=await ref.read(linkedWalletRepositoryProvider).load(_user!,widget.profile);if(mounted && _same && g==_generation) {setState(()=>_rows=rows);}}
    catch(_){if(mounted && _same && g==_generation) {setState(()=>_failed=true);}}
    finally{if(mounted && g==_generation) {setState(()=>_busy=false);}}
  }
  @override
  void dispose(){_generation++;_subscription?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override
  Widget build(BuildContext context){final l=AppLocalizations.of(context);return Scaffold(appBar:AppBar(title:Text(l.linkedWalletTitle)),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:850),child:ListView(padding:const EdgeInsets.all(20),children:[
    Text(l.linkedWalletHelp),const SizedBox(height:16),
    if(!_same) Text(l.contactSessionChanged)
    else if(_busy) const LinearProgressIndicator()
    else if(_failed) ...[Text(l.walletLoadFailed),OutlinedButton(onPressed:_load,child:Text(l.retry))]
    else ...[
      TextButton.icon(onPressed:_load,icon:const Icon(Icons.refresh),label:Text(l.authCheckAgain)),
      if(_rows.isEmpty) Text(l.linkedWalletEmpty),
      for(final row in _rows) Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Text(realValue(row['partner']),style:Theme.of(context).textTheme.titleLarge),
        Text(row['environment']=='live'?l.partnerLive:l.partnerSandbox),
        SelectableText('${l.linkedReference}: ${realValue(row['reference'])}'),
        Text(row['connected']==true?l.partnerConnected:l.partnerNotConnected),
        if(row['snapshot']==null) Text(l.linkedNoSnapshot)
        else ...[
          const SizedBox(height:12),
          Text('${l.linkedAvailable}: ${realValue(row['snapshot']['available'])} ${realValue(row['currency'])}'),
          Text('${l.walletHeld}: ${realValue(row['snapshot']['held'])} ${realValue(row['currency'])}'),
          Text('${l.linkedPending}: ${realValue(row['snapshot']['pending'])} ${realValue(row['currency'])}'),
          Text('${l.linkedObserved}: ${adminDate(context,row['snapshot']['observed_at'])}'),
          if(row['snapshot']['stale']==true) Text(l.linkedStale,style:TextStyle(color:Theme.of(context).colorScheme.error)),
        ],
        Text(l.linkedUnreconciled),
        if((row['updates'] as List? ?? []).isNotEmpty) ExpansionTile(title:Text(l.partnerHistory),children:[
          for(final update in row['updates'] as List) ListTile(title:Text(update['outcome']=='applied'?l.linkedApplied:l.linkedOlder),subtitle:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(adminDate(context,update['created_at'])),SelectableText(realValue(update['receipt_id']))])),
        ]),
      ]))),
    ],
  ])))));}
}
