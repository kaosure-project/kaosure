begin;
-- Synthetic storage metadata only; all changes below roll back.
do $test$
declare u uuid; d uuid:=gen_random_uuid();
begin
 select id into u from public.profiles p where account_status='active' and deleted_at is null
 and not exists(select 1 from public.verification_requests r where r.requested_by=p.id and r.status in ('pending','under_review'))
 and not exists(select 1 from public.identity_documents x where x.owner_id=p.id and x.document_type='residence_card' and x.deleted_at is null and x.status in ('pending_review','approved')) limit 1;
 if u is null then raise exception 'no_available_test_account'; end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','is_anonymous',false)::text,true);
 perform set_config('r8b.id',d::text,true);
 insert into storage.objects(bucket_id,name,owner_id,metadata) values
 ('identity-documents',u::text||'/residence/'||d::text||'/front.jpg',u::text,'{"size":1024,"mimetype":"image/jpeg"}');
end $test$;
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8b.id')::uuid; prefix text:=auth.uid()::text||'/residence/'||d::text;
begin
 begin
  perform public.submit_residence_r8b(d,'TEST-RES','Test','Family',false,false,'TEST AUTHORITY','card',false,current_date-365,current_date+365,prefix||'/front.jpg',prefix||'/back.jpg');
  raise exception 'missing_back_accepted';
 exception when invalid_parameter_value then null;
 end;
 if exists(select 1 from public.identity_documents where id=d) then raise exception 'partial_document_left'; end if;
 perform public.submit_residence_r8b(d,'TEST-RES','Test','',true,false,'TEST AUTHORITY','paper',true,current_date-365,null,prefix||'/front.jpg',null);
 perform public.submit_residence_r8b(d,'TEST-RES','Test','',true,false,'TEST AUTHORITY','paper',true,current_date-365,null,prefix||'/front.jpg',null);
 if (select count(*) from public.verification_requests where document_id=d and status='pending')<>1 then raise exception 'duplicate_request'; end if;
 if (select count(*) from public.document_files where document_id=d)<>1 then raise exception 'paper_file_count'; end if;
 if not exists(select 1 from public.identity_documents where id=d and status='pending_review' and no_expiry and single_name and expiry_date is null) then raise exception 'wrong_state'; end if;
 begin
  perform public.submit_residence_r8b(d,'CHANGED','Test','',true,false,'TEST AUTHORITY','paper',true,current_date-365,null,prefix||'/front.jpg',null);
  raise exception 'modified_retry_accepted';
 exception when insufficient_privilege then null;
 end;
 begin
  perform public.submit_residence_r8b(d,'TEST-RES','Test','',true,false,'TEST AUTHORITY','paper',false,current_date-365,current_date-1,prefix||'/front.jpg',null);
  raise exception 'expired_accepted';
 exception when invalid_parameter_value then null;
 end;
end $test$;
reset role;
-- End the synthetic paper request inside this rollback-only transaction to test a card.
update public.verification_requests set status='rejected' where document_id=current_setting('r8b.id')::uuid;
update public.identity_documents set status='rejected' where id=current_setting('r8b.id')::uuid;
do $test$
declare d uuid:=gen_random_uuid();
begin
 perform set_config('r8b.card',d::text,true);
 insert into storage.objects(bucket_id,name,owner_id,metadata)
 select 'identity-documents',auth.uid()::text||'/residence/'||d::text||'/'||side||'.jpg',auth.uid()::text,'{"size":1024,"mimetype":"image/jpeg"}'::jsonb from unnest(array['front','back']) side;
end $test$;
set local role authenticated;
do $test$
declare d uuid:=current_setting('r8b.card')::uuid; prefix text:=auth.uid()::text||'/residence/'||d::text; n uuid:=gen_random_uuid();
begin
 perform public.submit_residence_r8b(d,'TEST-CARD','Test','Family',false,true,'TEST AUTHORITY','card',false,current_date-365,current_date+365,prefix||'/front.jpg',prefix||'/back.jpg');
 if (select count(*) from public.document_files where document_id=d)<>2 then raise exception 'card_file_count'; end if;
 if not exists(select 1 from public.identity_documents where id=d and full_name='Family Test' and residence_format='card') then raise exception 'wrong_names'; end if;
 begin
  perform public.submit_residence_r8b(n,'ANOTHER','Test','',true,false,'TEST AUTHORITY','paper',true,current_date-365,null,auth.uid()::text||'/residence/'||n::text||'/front.jpg',null);
  raise exception 'parallel_request_accepted';
 exception when object_not_in_prerequisite_state then null;
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
 if exists(select 1 from public.identity_documents where id=current_setting('r8b.card')::uuid)
 or exists(select 1 from public.document_files where document_id=current_setting('r8b.card')::uuid) then raise exception 'foreign_owner_read'; end if;
end $test$;
reset role;
select 'PASS: missing-side rejection, atomic save, paper/card, single name, immutable retry, expiry, pending guard and owner RLS' as result;
rollback;
