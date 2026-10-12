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
 -- Legacy profile labels cannot grant administrative access.
 update public.profiles set role='super_admin' where id=u;
 if public.is_admin() then raise exception 'profile label elevated';end if;
 update public.admin_assignments set starts_at=now()-interval '1 day',expires_at=now() where id=a;
 if public.is_active_admin() or public.can_review_kyc_r7c() or public.has_permission('admin.dashboard.view') then raise exception 'expiry boundary allowed';end if;
 update public.admin_assignments set expires_at=null,starts_at=now()+interval '1 hour' where id=a;
 if public.is_active_admin() then raise exception 'future assignment allowed';end if;
 update public.admin_assignments set starts_at=now() where id=a;
 update public.profiles set account_status='suspended' where id=u;
 if public.is_active_admin() or public.can_access_admin() then raise exception 'suspension allowed';end if;
end $$;
select 'expiry, future assignment, suspension and legacy profile label: passed; rolled back' result;
rollback;