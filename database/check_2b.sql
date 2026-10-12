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
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',gen_random_uuid())::text,true);
 if public.is_active_admin() or public.can_review_kyc_r7c() then raise exception 'revoked session allowed';end if;

end $$;
select 'revoked session: passed; rolled back' result;
rollback;