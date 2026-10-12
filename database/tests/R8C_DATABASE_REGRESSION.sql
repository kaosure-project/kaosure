begin;
-- Synthetic metadata only. No money movement, approval or lasting test records.
do $test$
declare u uuid; d uuid:=gen_random_uuid();
begin
 select id into u from public.profiles p where account_status='active' and deleted_at is null
 and not exists(select 1 from public.bank_accounts b where b.profile_id=p.id) limit 1;
 if u is null then raise exception 'no_available_test_account'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','is_anonymous',false)::text,true);
 perform set_config('r8c.id',d::text,true);
end $test$;
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8c.id')::uuid; path text:=auth.uid()::text||'/bank-account/'||d::text||'/evidence.jpg';
begin
 begin
  perform public.submit_bank_r8c(d,'TEST BANK','Élodie','0012345678','','savings',path);
  raise exception 'missing_file_accepted';
 exception when invalid_parameter_value then null;
 end;
 if exists(select 1 from public.bank_accounts where id=d) then raise exception 'partial_account_left'; end if;
end $test$;
reset role;
insert into storage.objects(bucket_id,name,owner_id,metadata) values
 ('identity-documents',auth.uid()::text||'/bank-account/'||current_setting('r8c.id')||'/evidence.jpg',auth.uid()::text,'{"size":1024,"mimetype":"image/jpeg"}');
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8c.id')::uuid; path text:=auth.uid()::text||'/bank-account/'||d::text||'/evidence.jpg'; j jsonb; n uuid:=gen_random_uuid();
begin
 perform public.submit_bank_r8c(d,'TEST BANK','Élodie','0012345678','','savings',path);
 perform public.submit_bank_r8c(d,'TEST BANK','Élodie','0012345678','','savings',path);
 if (select count(*) from public.bank_accounts where id=d and status='pending' and not is_verified and not is_default and account_number='0012345678')<>1 then raise exception 'wrong_account_state'; end if;
 j:=public.list_banks_r8c();
 if jsonb_array_length(j)<>1 or j->0->>'account_number'<>'•••• 5678' or j->0->>'status'<>'pending'
  or j->0->>'name_match_status'<>'pending' or j->0->>'evidence_path'<>path then raise exception 'wrong_list'; end if;
 begin
  perform public.submit_bank_r8c(d,'TEST BANK','Changed','0012345678','','savings',path);
  raise exception 'changed_retry_accepted';
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.submit_bank_r8c(n,'TEST BANK','Élodie','0012345679','','savings',auth.uid()::text||'/bank-account/'||n::text||'/evidence.jpg');
  raise exception 'parallel_bank_request_accepted';
 exception when object_not_in_prerequisite_state then null;
 end;
 begin
  update public.bank_accounts set is_verified=true where id=d;
  raise exception 'self_verification_allowed';
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.submit_bank_r8c(n,'TEST BANK','Élodie','123','','savings',path);
  raise exception 'invalid_number_accepted';
 exception when invalid_parameter_value then null;
 end;
end $test$;
reset role;
do $test$
begin
 if (select count(*) from public.financial_verifications where bank_account_id=current_setting('r8c.id')::uuid
 and status='pending' and name_match_status='pending' and verified_at is null)<>1 then raise exception 'wrong_financial_state'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',gen_random_uuid(),'role','authenticated')::text,true);
end $test$;
set local role authenticated;
do $test$
begin
 if exists(select 1 from public.bank_accounts where id=current_setting('r8c.id')::uuid) then raise exception 'foreign_owner_read'; end if;
 if exists(select 1 from storage.objects where name like '%/'||current_setting('r8c.id')||'/evidence.jpg') then raise exception 'foreign_evidence_read'; end if;
 begin
  perform public.list_banks_r8c();
  raise exception 'non_profile_list_accepted';
 exception when insufficient_privilege then null;
 end;
end $test$;
reset role;
select 'PASS: atomic submission, evidence requirement, pending-only, masked list, immutable retry, duplicate guard, validation and owner access' as result;
rollback;
