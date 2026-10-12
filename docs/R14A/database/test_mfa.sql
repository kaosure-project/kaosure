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
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 if not kaoid_private.can_review_r7c() then raise exception 'valid MFA denied';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal1')::text,true);
 if kaoid_private.can_review_r7c() then raise exception 'low assurance allowed';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 update auth.mfa_amr_claims set updated_at=now()-interval '11 minutes' where session_id=sa;
 begin perform kaoid_private.review_decision_r7c(req,false,'Test refusal');raise exception 'stale MFA allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
 if not exists(select 1 from public.notifications where profile_id=a and message='security_factor_added') then raise exception 'MFA notification missing';end if;
 if has_function_privilege('authenticated','kaoid_private.review_decision_base_r10e(uuid,boolean,text)','execute') then raise exception 'base bypass open';end if;
end $$;
select 'R14A mfa passed; fixtures rolled back' result;
rollback;
