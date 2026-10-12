-- SQL-only regression. Synthetic storage metadata; no real file upload.
-- All data changes are rolled back. Requires database administrator role.
begin;

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
rollback;
