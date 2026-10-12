begin;
do $$
declare u uuid:=gen_random_uuid();o uuid;d uuid:=gen_random_uuid();e uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();osid uuid:=gen_random_uuid();k text;qty integer; fresh uuid:=gen_random_uuid(); path text;
begin
 select profile_id into strict o from public.company_owners limit 1;
 insert into auth.users(id,email) values(u,'r11-doc-'||u||'@example.invalid');
 insert into public.profiles(id,seller_level,username) values(u,'standard','r11-doc-'||u) on conflict(id) do nothing;
 insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now()),(osid,o,now(),now());
 insert into public.verifications(profile_id,status) values(u,'approved') on conflict(profile_id) do update set status='approved';
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,status,issued_date,expiry_date)
 values(d,u,'thai_national_id','1234567890123','Test Name','approved',current_date-100,current_date+1);
 insert into public.verification_requests(document_id,requested_by,status,reviewed_by,reviewed_at) values(d,u,'approved',o,now());
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 k:=kaoid_private.issue_kao_id_r7c(u);
 begin perform public.revoke_document_r11a(d,'Cannot revoke self');raise exception 'self allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
 begin perform public.document_health_r11a(o);raise exception 'cross-account health allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',o,'role','authenticated','session_id',osid)::text,true);
 perform public.revoke_document_r11a(d,'Evidence reviewed and invalidated');
 perform public.revoke_document_r11a(d,'Retry unchanged request');
 if (select count(*) from public.activity_logs where target_id=d and action='kyc.revoke')<>1 then raise exception 'duplicate revocation';end if;
 if not exists(select 1 from public.kao_id_identities where profile_id=u and kao_id=k and status='suspended') then raise exception 'ID not retained suspended';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 begin perform kaoid_private.issue_kao_id_r7c(u);raise exception 'revoked ID issued' using errcode='XX001';exception when insufficient_privilege then null;end;
 -- Expiry preserves the record and creates one notice. Tests are rolled back.
 perform set_config('request.jwt.claims','{}',true);
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,status,issued_date,expiry_date)
 values(e,u,'passport','R11TEST','Test Name','approved',current_date-100,current_date-1);
 insert into public.verification_requests(document_id,requested_by,status,reviewed_by,reviewed_at) values(e,u,'approved',o,now());
 perform kaoid_private.expire_documents_r11a();perform kaoid_private.expire_documents_r11a();
 if (select status from public.identity_documents where id=e)<>'expired' then raise exception 'expiry missing';end if;
 if (select count(*) from public.notifications where target_id=e and message='kyc_expired')<>1 then raise exception 'expiry duplicate';end if;
 -- Submit and approve an actual replacement through the existing central APIs.
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 foreach path in array array[u||'/national-id/'||fresh||'/front.jpg',u||'/national-id/'||fresh||'/back.jpg'] loop
  insert into storage.objects(bucket_id,name,owner_id,metadata) values('identity-documents',path,u::text,'{"size":100,"mimetype":"image/jpeg"}');
 end loop;
 perform kaoid_private.submit_national_id_r7a(fresh,'1234567890123','Test Name',current_date-1,current_date+365,u||'/national-id/'||fresh||'/front.jpg',u||'/national-id/'||fresh||'/back.jpg');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',o,'role','authenticated','session_id',osid)::text,true);
 perform kaoid_private.review_decision_r7c((select id from public.verification_requests where document_id=fresh),true,'Replacement evidence checked');
 if not exists(select 1 from public.kao_id_identities where profile_id=u and kao_id=k and status='active') then raise exception 'original ID not reactivated';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 if kaoid_private.issue_kao_id_r7c(u)<>k then raise exception 'ID changed';end if;
 if exists(select 1 from public.admin_assignments where profile_id=u and is_active) then raise exception 'staff restored';end if;
end $$;
select 'R11A: revoke/expiry, real replacement submit/review, same ID, no role restoration: passed (rollback)' as result;
rollback;
