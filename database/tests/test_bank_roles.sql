begin;
do $$
declare u uuid:=gen_random_uuid();a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();o uuid;sa uuid:=gen_random_uuid();sb uuid:=gen_random_uuid();fa uuid:=gen_random_uuid();fb uuid:=gen_random_uuid();d uuid:=gen_random_uuid();req uuid;aid uuid;notice uuid;bank uuid:=gen_random_uuid();
begin
 select profile_id into strict o from public.company_owners;
 insert into auth.users(id,email,email_confirmed_at) values(u,'r14-'||u||'@example.invalid',now()),(a,'r14-'||a||'@example.invalid',now()),(b,'r14-'||b||'@example.invalid',now());
 insert into public.profiles(id,seller_level,username) values(u,'standard','r14-'||u),(a,'standard','r14-'||a),(b,'standard','r14-'||b) on conflict(id) do nothing;
 insert into public.admin_assignments(profile_id,role_id,assigned_by,starts_at,is_active) select x,id,o,now(),true from public.admin_roles cross join unnest(array[a,b]) x where code='kyc_officer';
 insert into auth.mfa_factors(id,user_id,factor_type,status,created_at,updated_at) values(fa,a,'totp','verified',now(),now()),(fb,b,'totp','verified',now(),now());
 insert into auth.sessions(id,user_id,created_at,updated_at,aal,factor_id) values(sa,a,now(),now(),'aal2',fa),(sb,b,now(),now(),'aal2',fb);
 insert into auth.mfa_amr_claims(id,session_id,authentication_method,created_at,updated_at) values(gen_random_uuid(),sa,'totp',now(),now()),(gen_random_uuid(),sb,'totp',now(),now());

 insert into public.bank_accounts(id,profile_id,bank_name,bank_code,branch_name,account_name,account_number,evidence_path)
 values(bank,u,'Rollback Bank','TEST','Test','Rollback Person','0123456789',u::text||'/bank-account/'||bank::text||'/evidence.jpg');
 insert into public.financial_verifications(bank_account_id,profile_id,identity_type,status) values(bank,u,'personal','pending') returning id into req;
 if (select count(*) from public.notifications where profile_id in(a,b) and target_id=req and message='review_new')<>2 then raise exception 'bank reviewers missing';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 select id into notice from public.notifications where profile_id=a and target_id=req and message='review_new';
 set local role authenticated;
 if public.kaoid_notice_target_r14b(notice)->'row'->>'document_type'<>'bank' then raise exception 'bank target failed';end if;
 reset role;
 select id into aid from public.admin_assignments where profile_id=a;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(o,'governance.role.assign','admin_assignments',aid,'Rollback test');
 select id into notice from public.notifications where profile_id=a and target_id=aid and message='role_assigned';
 if notice is null then raise exception 'assignment notice missing';end if;
 set local role authenticated;
 if not (public.kaoid_notice_target_r14b(notice)->>'active')::boolean then raise exception 'active role unavailable';end if;
 reset role;
 update public.admin_assignments set is_active=false where id=aid;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(o,'governance.role.revoke','admin_assignments',aid,'Rollback test');
 if not exists(select 1 from public.notifications where profile_id=a and target_id=aid and message='role_revoked') then raise exception 'revoke notice missing';end if;
 set local role authenticated;
 if (public.kaoid_notice_target_r14b(notice)->>'active')::boolean then raise exception 'old notice restored role';end if;
 reset role;
 if has_function_privilege('authenticated','kaoid_private.review_target_base_r14b(uuid)','execute') or has_function_privilege('anon','public.kaoid_notice_target_r14b(uuid)','execute') then raise exception 'unsafe grants';end if;
end $$;
select 'R14B bank and role notices passed; fixtures rolled back' result;
rollback;
