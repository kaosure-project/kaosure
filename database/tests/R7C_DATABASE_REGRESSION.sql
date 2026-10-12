-- SQL transaction only; every test row and temporary role is rolled back.
begin;
-- SQL-only regression. Synthetic storage metadata; no real file upload.
-- All data changes are rolled back. Requires database administrator role.


do $test$
declare v_uid uuid;
begin
 select p.id into v_uid from public.profiles p
 where not exists(select 1 from public.verification_requests r where r.requested_by=p.id and r.status in ('pending','under_review'))
 and not exists(select 1 from public.identity_documents d where d.owner_id=p.id and d.document_type='thai_national_id' and d.status in ('approved','pending_review') and d.deleted_at is null)
 limit 1;
 if v_uid is null then raise exception 'no_test_candidate'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_uid,'role','authenticated','is_anonymous',false)::text,true);
 perform set_config('r7.doc',gen_random_uuid()::text,true);
 insert into storage.objects(bucket_id,name,owner_id,metadata)
 select 'identity-documents',v_uid::text||'/national-id/'||current_setting('r7.doc')||'/'||side||'.jpg',v_uid::text,
 '{"size":1024,"mimetype":"image/jpeg"}'::jsonb from unnest(array['front','back']) side;
end;
$test$;
set local role authenticated;
do $test$
declare
 v_id uuid := current_setting('r7.doc')::uuid;
 v_prefix text := auth.uid()::text||'/national-id/'||v_id::text;
 v_result uuid;
begin
 v_result := public.submit_national_id_r7a(v_id,'0000000000000','TEST ONLY ROLLBACK',current_date-365,current_date+365,v_prefix||'/front.jpg',v_prefix||'/back.jpg');
 if v_result<>v_id then raise exception 'incorrect_id'; end if;
 if (select count(*) from public.document_files where document_id=v_id)<>2 then raise exception 'missing_files'; end if;
 if not exists(select 1 from public.identity_documents where id=v_id and status='pending_review') then raise exception 'incorrect_status'; end if;
 if (select count(*) from public.verification_requests where document_id=v_id and status='pending')<>1 then raise exception 'missing_request'; end if;
 perform public.submit_national_id_r7a(v_id,'0000000000000','TEST ONLY ROLLBACK',current_date-365,current_date+365,v_prefix||'/front.jpg',v_prefix||'/back.jpg');
 if (select count(*) from public.verification_requests where document_id=v_id)<>1 then raise exception 'duplicate_request'; end if;
 begin
  perform public.submit_national_id_r7a(gen_random_uuid(),'0000000000000','TEST ONLY ROLLBACK',current_date-365,current_date+365,'foreign/front.jpg','foreign/back.jpg');
  raise exception 'invalid_path_accepted';
 exception when invalid_parameter_value then null;
 end;
end;
$test$;
reset role;
do $test$
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',gen_random_uuid(),'role','authenticated')::text,true);
end;
$test$;
set local role authenticated;
do $test$
begin
 if exists(select 1 from public.identity_documents where id=current_setting('r7.doc')::uuid)
 or exists(select 1 from public.document_files where document_id=current_setting('r7.doc')::uuid)
 then raise exception 'foreign_owner_can_read'; end if;
end;
$test$;
reset role;

do $test$
declare v_owner uuid; v_reviewer uuid;
begin
 select owner_id into v_owner from public.identity_documents where id=current_setting('r7.doc')::uuid;
 select id into v_reviewer from public.profiles where id<>v_owner and account_status='active' limit 1;
 if v_reviewer is null then raise exception 'second_account_needed'; end if;
 perform set_config('r7.owner',v_owner::text,true);
 perform set_config('r7.reviewer',v_reviewer::text,true);
 perform set_config('r7.request',(select id::text from public.verification_requests where document_id=current_setting('r7.doc')::uuid),true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_owner,'role','authenticated')::text,true);
end $test$;
set local role authenticated;
do $test$
begin
 begin
  update public.profiles set role='kyc_officer' where id=auth.uid();
  raise exception 'self_role_change_allowed';
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.issue_kao_id(auth.uid());
  -- A pre-existing active ID is allowed; new issuance is not.
  if not exists(select 1 from public.kao_id_identities where profile_id=auth.uid()) then raise exception 'early_issue'; end if;
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.kyc_review_decision_r7c(current_setting('r7.request')::uuid,true,null);
  raise exception 'ordinary_user_review_allowed';
 exception when insufficient_privilege then null;
 end;
end $test$;
reset role;
-- Scoped test role, rolled back; never grants a real permanent reviewer.
insert into public.admin_assignments(profile_id,role_id,assigned_by) select current_setting('r7.reviewer')::uuid,id,current_setting('r7.reviewer')::uuid from public.admin_roles where code='kyc_officer';
do $test$ begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('r7.reviewer'),'role','authenticated')::text,true);
end $test$;
set local role authenticated;
do $test$
begin
 if not public.can_review_kyc_r7c() then raise exception 'reviewer_not_recognized'; end if;
 if not exists(select 1 from jsonb_array_elements(public.kyc_review_queue_r7c()) q where q->>'id'=current_setting('r7.request')) then raise exception 'queue_missing'; end if;
 perform public.kyc_review_decision_r7c(current_setting('r7.request')::uuid,true,'TEST ONLY ROLLBACK');
 perform public.kyc_review_decision_r7c(current_setting('r7.request')::uuid,true,'TEST ONLY ROLLBACK');
end $test$;
reset role;
do $test$ begin
 if (select count(*) from public.verification_logs where verification_request_id=current_setting('r7.request')::uuid and action='approve')<>1 then raise exception 'duplicate_audit'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('r7.owner'),'role','authenticated')::text,true);
end $test$;
set local role authenticated;
do $test$
declare a text; b text;
begin
 if not exists(select 1 from public.identity_documents where id=current_setting('r7.doc')::uuid and status='approved') then raise exception 'document_not_updated'; end if;
 a:=public.issue_kao_id(auth.uid()); b:=public.issue_kao_id(auth.uid());
 if a is null or a<>b then raise exception 'issue_not_idempotent'; end if;
 if (select count(*) from public.kao_id_identities where profile_id=auth.uid())<>1 then raise exception 'multiple_identities'; end if;
end $test$;
reset role;
rollback;

