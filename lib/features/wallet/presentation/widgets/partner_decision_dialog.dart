import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class PartnerDecisionDialog extends StatefulWidget {
  const PartnerDecisionDialog({super.key, required this.title,required this.name});
  final String title,name;
  @override
  State<PartnerDecisionDialog> createState()=>_DecisionDialogState();
}

class _DecisionDialogState extends State<PartnerDecisionDialog>{
  final _reason=TextEditingController();
  @override
  void dispose(){_reason.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){final l=AppLocalizations.of(context);return AlertDialog(title:Text(widget.title),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(widget.name),Text(l.partnerConfirm),TextField(controller:_reason,maxLength:500,decoration:InputDecoration(labelText:l.partnerReason),onChanged:(_)=>setState((){})),
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(l.cancel)),FilledButton(onPressed:_reason.text.trim().length>=3?()=>Navigator.pop(context,_reason.text.trim()):null,child:Text(l.continueLabel))]);}
}
