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
 insert into storage.objects(bucket_id,name,owner_id,metadata) values
 ('identity-documents',u||'/national-id/'||d||'/front.jpg',u::text,'{"size":100,"mimetype":"image/jpeg"}'),
 ('identity-documents',u||'/national-id/'||d||'/back.jpg',u::text,'{"size":100,"mimetype":"image/jpeg"}');
 insert into public.document_files(document_id,file_path,file_name,mime_type,file_size) values
 (d,u||'/national-id/'||d||'/front.jpg','front.jpg','image/jpeg',100),(d,u||'/national-id/'||d||'/back.jpg','back.jpg','image/jpeg',100);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 if kaoid_private.review_decision_r7c(req,true,'First checked') then raise exception 'single approved';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated','session_id',sb,'aal','aal2')::text,true);
 if not kaoid_private.review_decision_r7c(req,true,'Second checked') then raise exception 'approval failed';end if;
 if (select status from public.verification_requests where id=req)<>'approved' then raise exception 'not approved';end if;
 if (select count(*) from public.approval_steps s join public.approval_requests r on r.id=s.approval_request_id where r.resource_id=req)<>2 then raise exception 'wrong vote count';end if;
end $$;
select 'R14A two-person approval passed; rollback' result;
rollback;