begin;
do $$
declare o uuid;u uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();osid uuid:=gen_random_uuid();a uuid;rid uuid;v jsonb;
begin
 select profile_id into strict o from public.company_owners;
 insert into auth.users(id,email,email_confirmed_at) values(u,'r13-'||u||'@example.invalid',now());
 insert into public.profiles(id,seller_level,username) values(u,'standard','r13-'||u) on conflict(id) do nothing;
 insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now()),(osid,o,now(),now());
 perform set_config('request.jwt.claims',jsonb_build_object('sub',o,'role','authenticated','session_id',osid)::text,true);
 a:=public.staff_assign_r13a(o,u::text,'kyc_officer');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',o,'role','authenticated','session_id',osid)::text,true);
 set local role authenticated;
 perform public.staff_revoke_r13a(o,a);perform public.staff_revoke_r13a(o,a);
 reset role;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 if public.is_active_admin() or public.can_review_kyc_r7c() or public.can_access_admin() then raise exception 'revocation stale';end if;
 if has_function_privilege('anon','public.can_access_admin()','execute') or has_function_privilege('anon','public.has_permission(text)','execute') then raise exception 'anonymous RPC open';end if;
 if has_function_privilege('authenticated','public.approve_financial_verification(uuid,uuid,text,text)','execute') or has_function_privilege('authenticated','public.approve_business_kyc(uuid,uuid,text)','execute') then raise exception 'legacy approval reopened';end if;
 if (select count(*) from public.activity_logs where target_id=a and action in ('governance.role.assign','governance.role.revoke'))<>2 then raise exception 'retry audit duplicated';end if;
end $$;
select 'R13A group 3 passed, rolled back' result;
rollback;
