create or replace function kaoid_private.account_active_r9f() returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and exists(select 1 from public.profiles where id=auth.uid() and account_status='active' and deleted_at is null);
$$;
revoke all on function kaoid_private.account_active_r9f() from public,anon;
grant execute on function kaoid_private.account_active_r9f() to authenticated;

create or replace function kaoid_private.guard_account_write_r9f() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is not null and exists(select 1 from public.profiles where id=auth.uid() and (account_status<>'active' or deleted_at is not null)) then
 raise exception 'account_restricted' using errcode='42501'; end if;
 if tg_op='DELETE' then return old; end if; return new;
end $$;
revoke all on function kaoid_private.guard_account_write_r9f() from public,anon,authenticated;

create or replace function kaoid_private.guard_account_state_r9f() returns trigger
language plpgsql set search_path='' as $$
begin
 if current_user in ('authenticated','anon') and
 ((tg_op='INSERT' and (new.account_status is distinct from 'active' or new.deleted_at is not null))
 or (tg_op='UPDATE' and (new.account_status is distinct from old.account_status or new.deleted_at is distinct from old.deleted_at))) then
 raise exception 'account_state_requires_owner' using errcode='42501'; end if;
 return new;
end $$;
revoke all on function kaoid_private.guard_account_state_r9f() from public,anon,authenticated;
create trigger protect_account_state_r9f before insert or update on public.profiles for each row execute function kaoid_private.guard_account_state_r9f();
do $$ declare t text; begin
 foreach t in array array['profiles','identity_documents','document_files','verification_requests','verifications','verification_logs','bank_accounts','financial_verifications','kao_id_identities','admin_assignments','owner_delegations'] loop
 execute format('create trigger account_write_guard_r9f before insert or update or delete on public.%I for each row execute function kaoid_private.guard_account_write_r9f()',t);
 end loop;
end $$;
create policy restricted_kyc_storage_r9f on storage.objects as restrictive for all to authenticated
using(bucket_id<>'identity-documents' or kaoid_private.account_active_r9f())
with check(bucket_id<>'identity-documents' or kaoid_private.account_active_r9f());

create or replace function kaoid_private.set_account_state_r9f(p_target uuid,p_expected text,p_next text,p_reason text) returns boolean
language plpgsql security definer set search_path='' as $$
declare previous text;
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 if p_target=auth.uid() or exists(select 1 from public.company_owners where profile_id=p_target) then raise exception 'owner_role_protected' using errcode='42501'; end if;
 if p_next is null or p_expected is null or p_next not in ('active','suspended') or p_expected not in ('active','suspended')
 or length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_account_action' using errcode='22023'; end if;
 select account_status into previous from public.profiles where id=p_target and deleted_at is null for update;
 if not found or previous not in ('active','suspended') then raise exception 'target_unavailable'; end if;
 if previous=p_next then return true; end if;
 if previous<>p_expected then raise exception 'account_state_changed'; end if;
 update public.profiles set account_status=p_next,updated_at=now() where id=p_target;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'account.'||case when p_next='suspended' then 'suspend' else 'restore' end,'profiles',p_target,
 jsonb_build_object('previous',previous,'next',p_next,'reason',btrim(p_reason))::text);
 return true;
end $$;
create or replace function kaoid_private.account_history_r9f(p_target uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501'; end if;
 return (select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select id,profile_id as actor_id,action,description,created_at from public.activity_logs
 where target_table='profiles' and target_id=p_target and action in ('account.suspend','account.restore') order by created_at desc,id desc limit 50)x);
end $$;
revoke all on function kaoid_private.set_account_state_r9f(uuid,text,text,text),kaoid_private.account_history_r9f(uuid) from public,anon;
grant execute on function kaoid_private.set_account_state_r9f(uuid,text,text,text),kaoid_private.account_history_r9f(uuid) to authenticated;
create or replace function public.set_account_state_r9f(p_target uuid,p_expected text,p_next text,p_reason text) returns boolean language sql security invoker set search_path='' as $$ select kaoid_private.set_account_state_r9f(p_target,p_expected,p_next,p_reason); $$;
create or replace function public.account_history_r9f(p_target uuid) returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.account_history_r9f(p_target); $$;
revoke all on function public.set_account_state_r9f(uuid,text,text,text),public.account_history_r9f(uuid) from public,anon;
grant execute on function public.set_account_state_r9f(uuid,text,text,text),public.account_history_r9f(uuid) to authenticated;
