create or replace function kaoid_private.can_read_members_r9a() returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null
 and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and exists(select 1 from public.company_owners o join public.profiles p on p.id=o.profile_id
 where o.profile_id=auth.uid() and p.account_status='active' and p.deleted_at is null);
$$;
revoke all on function kaoid_private.can_read_members_r9a() from public,anon;
grant execute on function kaoid_private.can_read_members_r9a() to authenticated;
create or replace function public.can_read_members_r9a() returns boolean language sql stable
security invoker set search_path='' as $$ select kaoid_private.can_read_members_r9a(); $$;
revoke all on function public.can_read_members_r9a() from public,anon;
grant execute on function public.can_read_members_r9a() to authenticated;
create or replace function kaoid_private.find_member_r9a(p_query text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare q text:=btrim(p_query); result jsonb; target uuid;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'member_access_denied' using errcode='42501'; end if;
 if q is null or length(q)<3 or length(q)>254 then raise exception 'member_query_invalid' using errcode='22023'; end if;
 select jsonb_build_object('id',p.id,'display_name',p.display_name,'account_status',p.account_status,
 'email',u.email,'email_verified',u.email_confirmed_at is not null and coalesce(u.email,'')<>'',
 'phone',u.phone,'phone_verified',u.phone_confirmed_at is not null and coalesce(u.phone,'')<>'',
 'kyc_status',v.status,'kao_id',k.kao_id,'identity_status',k.status,'created_at',p.created_at)
 into result from public.profiles p join auth.users u on u.id=p.id
 left join public.verifications v on v.profile_id=p.id
 left join public.kao_id_identities k on k.profile_id=p.id
 where lower(u.email)=lower(q) or p.id::text=q or k.kao_id=upper(q)
 order by p.id limit 1;
 target:=(result->>'id')::uuid;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'governance.member.read','profiles',target,
 case when target is null then 'Exact member lookup: no match' else 'Read member summary' end);
 return result;
end $$;
revoke all on function kaoid_private.find_member_r9a(text) from public,anon;
grant execute on function kaoid_private.find_member_r9a(text) to authenticated;
create or replace function public.find_member_r9a(p_query text) returns jsonb language sql
security invoker set search_path='' as $$ select kaoid_private.find_member_r9a(p_query); $$;
revoke all on function public.find_member_r9a(text) from public,anon;
grant execute on function public.find_member_r9a(text) to authenticated;
;
