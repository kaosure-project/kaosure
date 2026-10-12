begin;
-- Synthetic storage metadata only. No real passport files or approvals.
-- All rows and temporary session claims are rolled back.
do $test$
declare u uuid;
begin
 select id into u from public.profiles p where account_status='active' and deleted_at is null
 and not exists(select 1 from public.verification_requests r where r.requested_by=p.id and r.status in ('pending','under_review'))
 and not exists(select 1 from public.identity_documents d where d.owner_id=p.id and d.document_type='passport' and d.deleted_at is null and d.status in ('pending_review','approved')) limit 1;
 if u is null then raise exception 'no_available_test_account'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','is_anonymous',false)::text,true);
 perform set_config('r8.id',gen_random_uuid()::text,true);
end $test$;
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8.id')::uuid; path text:=auth.uid()::text||'/passport/'||d::text||'/data.jpg';
begin
 begin
  perform public.submit_passport_r8a(d,'TEST001','Test','',true,false,'TEST AUTHORITY',current_date-10000,current_date-365,current_date+365,path);
  raise exception 'missing_upload_accepted';
 exception when invalid_parameter_value then null;
 end;
end $test$;
reset role;
insert into storage.objects(bucket_id,name,owner_id,metadata)
 values('identity-documents',auth.uid()::text||'/passport/'||current_setting('r8.id')||'/data.jpg',auth.uid()::text,'{"size":1024,"mimetype":"image/jpeg"}');
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8.id')::uuid; path text:=auth.uid()::text||'/passport/'||d::text||'/data.jpg'; n uuid;
begin
 perform public.submit_passport_r8a(d,'TEST001','Test','',true,false,'TEST AUTHORITY',current_date-10000,current_date-365,current_date+365,path);
 perform public.submit_passport_r8a(d,'TEST001','Test','',true,false,'TEST AUTHORITY',current_date-10000,current_date-365,current_date+365,path);
 if (select count(*) from public.verification_requests where document_id=d and status='pending')<>1 then raise exception 'request_count'; end if;
 if not exists(select 1 from public.identity_documents where id=d and status='pending_review' and single_name and full_name='Test') then raise exception 'document_incorrect'; end if;
 if (select count(*) from public.document_files where document_id=d)<>1 then raise exception 'file_missing'; end if;
 begin
  perform public.submit_passport_r8a(d,'CHANGED','Test','',true,false,'TEST AUTHORITY',current_date-10000,current_date-365,current_date+365,path);
  raise exception 'changed_retry_accepted';
 exception when insufficient_privilege then null;
 end;
 n:=gen_random_uuid();
 begin
  perform public.submit_passport_r8a(n,'TEST002','Test','Family',false,true,'TEST AUTHORITY',current_date-10000,current_date-365,current_date+365,auth.uid()::text||'/passport/'||n::text||'/data.jpg');
  raise exception 'second_pending_accepted';
 exception when object_not_in_prerequisite_state then null;
 end;
 begin
  perform public.submit_passport_r8a(d,'TEST001','Test','',true,false,'TEST AUTHORITY',current_date-10000,current_date-365,current_date-1,path);
  raise exception 'expired_accepted';
 exception when invalid_parameter_value then null;
 end;
end $test$;
reset role;
do $test$
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',gen_random_uuid(),'role','authenticated')::text,true);
end $test$;
set local role authenticated;
do $test$
begin
 if exists(select 1 from public.identity_documents where id=current_setting('r8.id')::uuid)
 or exists(select 1 from public.document_files where document_id=current_setting('r8.id')::uuid) then raise exception 'foreign_read'; end if;
end $test$;
reset role;
select 'PASS: atomic submission, same-ID retry, changed-payload rejection, active request block, expiry validation, foreign-owner RLS' as result;
rollback;
