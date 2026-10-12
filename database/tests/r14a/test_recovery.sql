begin;
do $$
declare u uuid:=gen_random_uuid();a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();o uuid;sa uuid:=gen_random_uuid();sb uuid:=gen_random_uuid();fa uuid:=gen_random_uuid();fb uuid:=gen_random_uuid();d uuid:=gen_random_uuid();req uuid;aid uuid;
begin
 select profile_id into strict o from public.company_owners;
 insert into auth.users(id,email,email_confirmed_at) values(u,'r14-'||u||'@example.invalid',now()),(a,'r14-'||a||'@example.invalid',now()),(b,'r14-'||b||'@example.invalid',now());
 insert into public.profiles(id,seller_level,username) values(u,'standard','r14-'||u),(a,'standard','r14-'||a),(b,'standard','r14-'||b) on conflict(id) do nothing;
 insert into public.admin_assignments(profile_id,role_id,assigned_by,starts_at,is_active) select x,id,o,now(),true from public.admin_roles cross join unnest(array[a,b]) x where code='kyc_officer';
 insert into auth.mfa_factors(id,user_id,factor_type,status,created_at,updated_at) values(fa,a,'totp','verified',now(),now()),(fb,b,'totp','verified',now(),now());
 insert into auth.sessions(id,user_id,created_at,updated_at,aal,factor_id) values(sa,a,now(),now(),'aal2',fa),(sb,b,now(),now(),'aal2',fb);
 insert into auth.mfa_amr_claims(id,session_id,authentication_method,created_at,updated_at) values(gen_random_uuid(),sa,'totp',now(),now()),(gen_random_uuid(),sb,'totp',now(),now());
 insert into public.verifications(profile_id,status) values(u,'pending') on conflict(profile_id) do update set status='pending';
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,status,issued_date,expiry_date) values(d,u,'thai_national_id','1234567890123','Rollback Person','pending_review',current_date-5,current_date+365);
 insert into public.verification_requests(document_id,requested_by,status) values(d,u,'pending') returning id into req;
 update kaoid_private.security_policy_r14a set mfa_required=true,dual_review=true where id;
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,status,issued_date,expiry_date) values(fa,u,'thai_national_id','1234567890123','Rollback Person','approved',current_date-30,current_date+10);
 insert into public.verification_requests(document_id,requested_by,status,reviewed_by,reviewed_at) values(fa,u,'approved',o,now());
 insert into storage.objects(bucket_id,name,owner_id,metadata) values
 ('identity-documents',u||'/old/front.jpg',u::text,'{"size":100,"mimetype":"image/jpeg"}'),
 ('identity-documents',u||'/national-id/'||d||'/front.jpg',u::text,'{"size":100,"mimetype":"image/jpeg"}'),
 ('identity-documents',u||'/national-id/'||d||'/back.jpg',u::text,'{"size":100,"mimetype":"image/jpeg"}');
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size) values
 (fa,u||'/old/front.jpg','front.jpg','image/jpeg',100),
 (d,u||'/national-id/'||d||'/front.jpg','front.jpg','image/jpeg',100),(d,u||'/national-id/'||d||'/back.jpg','back.jpg','image/jpeg',100);
 insert into public.kao_id_identities(profile_id,kao_id,status,identity_type,issued_at) values(u,'K'||upper(substr(replace(u::text,'-',''),1,10)),'closed','personal',now());
 insert into kaoid_private.lifecycle_requests_r10b(id,profile_id,kind,status,reason) values(fa,u,'closure','approved','Rollback closure'),(fb,u,'recovery','pending','Rollback recovery');
 insert into kaoid_private.account_closures_r10d(profile_id,request_id,closed_by,prior_access,reason) values(u,fa,o,'{}','Rollback closure');
 insert into kaoid_private.recovery_evidence_r10e(id,lifecycle_id,profile_id,document_type,previous_document,status) values(req,fb,u,'thai_national_id',fa,'submitted');
 update public.profiles set account_status='closed' where id=u;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 if public.review_recovery_r10e(req,true,'First recovery check',true) then raise exception 'one reviewer restored';end if;
 if (select account_status from public.profiles where id=u)<>'closed' then raise exception 'first vote reopened account';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated','session_id',sb,'aal','aal2')::text,true);
 if not public.review_recovery_r10e(req,true,'Second recovery check',true) then raise exception 'two reviewers did not restore';end if;
 if (select account_status from public.profiles where id=u)<>'active' then raise exception 'not restored';end if;
 if not exists(select 1 from public.kao_id_identities where profile_id=u and status='active' and kao_id='K'||upper(substr(replace(u::text,'-',''),1,10))) then raise exception 'original ID not retained';end if;
 if exists(select 1 from public.admin_assignments where profile_id=u and is_active) then raise exception 'staff restored';end if;
end $$;
select 'R14A two-person recovery, same ID, no staff restoration passed; rollback' result;
rollback;