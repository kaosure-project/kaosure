begin;
do $$
declare o uuid;u uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();osid uuid:=gen_random_uuid();a uuid;rid uuid;v jsonb;
begin
 select profile_id into strict o from public.company_owners;
 insert into auth.users(id,email,email_confirmed_at) values(u,'r13-'||u||'@example.invalid',now());
 insert into public.profiles(id,seller_level,username) values(u,'standard','r13-'||u) on conflict(id) do nothing;
 insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now()),(osid,o,now(),now());
 perform set_config('request.jwt.claims',jsonb_build_object('sub',o,'role','authenticated','session_id',osid)::text,true);
 set local role authenticated;
 if not public.is_company_owner() or not public.can_access_admin() or not public.is_admin() or not public.can_review_kyc_r7c() then raise exception 'owner denied';end if;
 begin perform public.staff_assign_r13a(u,u::text,'kyc_officer');raise exception 'actor spoof accepted' using errcode='XX001';exception when insufficient_privilege then null;end;
 a:=public.staff_assign_r13a(o,u::text,'kyc_officer');
 if public.staff_assign_r13a(o,u::text,'kyc_officer')<>a then raise exception 'retry duplicated assignment';end if;
 if not exists(select 1 from public.get_governance_admin_assignments() where assignment_id=a) then raise exception 'bootstrap reviewer missing from legacy list';end if;
 reset role;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
 set local role authenticated;
 if not public.is_active_admin() or not public.can_access_admin() or not public.can_review_kyc_r7c() or not public.has_permission('admin.dashboard.view') then raise exception 'bootstrap reviewer inconsistent';end if;
 if public.is_admin() or public.is_company_owner() or public.has_permission('admin.assignments.create') then raise exception 'reviewer elevated';end if;
 v:=public.get_governance_access();
 if v->>'can_assign_admin'<>'false' or jsonb_array_length(v->'roles')<>1 then raise exception 'snapshot inconsistent';end if;
 begin perform public.staff_revoke_r13a(u,a);raise exception 'nonowner mutated' using errcode='XX001';exception when insufficient_privilege then null;end;
 reset role;
end $$;
select 'R13A group 1 passed, rolled back' result;
rollback;
