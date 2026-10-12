import 'package:flutter/material.dart';
import 'package:kaosure/features/wallet/presentation/pages/partner_page.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class PartnerDraft {
  PartnerDraft(this.code,this.name,this.environment,this.capabilities);
  final String code,name,environment;
  final List<String> capabilities;
}

class PartnerForm extends StatefulWidget {
  const PartnerForm({super.key, required this.shipping});
  final bool shipping;
  @override
  State<PartnerForm> createState()=>_PartnerFormState();
}

class _PartnerFormState extends State<PartnerForm> {
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
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l.cancel)),FilledButton(onPressed:_valid?()=>Navigator.pop(context,PartnerDraft(_code.text.trim(),_name.text.trim(),_environment,_caps.toList())):null,child:Text(l.partnerAdd))]);}
}
