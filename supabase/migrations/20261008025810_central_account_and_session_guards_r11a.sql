-- R11A: centralized account restrictions and actual Auth session management.
create or replace function kaoid_private.account_access_r10d() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare u uuid:=auth.uid(); s text; deleted timestamptz; cutoff timestamptz;
begin
 if u is null then return jsonb_build_object('state','signed_out');end if;
 if not exists(select 1 from auth.sessions a where a.user_id=u and a.id::text=auth.jwt()->>'session_id'
   and (a.not_after is null or a.not_after>now())) then return jsonb_build_object('state','session_revoked');end if;
 select account_status,deleted_at into s,deleted from public.profiles where id=u;
 if not found or deleted is not null then return jsonb_build_object('state','unavailable');end if;
 select closed_at into cutoff from kaoid_private.account_closures_r10d where profile_id=u;
 if cutoff is not null and not exists(select 1 from auth.sessions where user_id=u
   and id::text=auth.jwt()->>'session_id' and created_at>cutoff) then return jsonb_build_object('state','session_revoked');end if;
 return jsonb_build_object('state',case when s in ('active','closed','suspended','banned','temporarily_locked') then s else 'unavailable' end);
end $$;
create or replace function kaoid_private.account_active_r9f() returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and kaoid_private.account_access_r10d()->>'state'='active';
$$;
create or replace function kaoid_private.pre_request_r10d() returns void
language plpgsql security definer set search_path='' as $$
declare st text; path text:=trim(both '/' from coalesce(current_setting('request.path',true),''));
begin
 if auth.uid() is null then return;end if;
 if path='rpc/account_access_r10d' then return;end if;
 st:=kaoid_private.account_access_r10d()->>'state';
 if st='active' then return;end if;
 if st='closed' and path in ('rpc/lifecycle_snapshot_r10b','rpc/lifecycle_submit_r10b','rpc/lifecycle_cancel_r10b','rpc/prepare_recovery_r10e','rpc/submit_recovery_r10e','rpc/recovery_snapshot_r10e') then return;end if;
 raise exception 'account_restricted' using errcode='42501';
end $$;
-- Superseded approval APIs are not a second path around the audited review queue.
revoke execute on function public.approve_business_kyc(uuid,uuid,text) from public,anon,authenticated;
revoke execute on function public.approve_financial_verification(uuid,uuid,text,text) from public,anon,authenticated;

create or replace function kaoid_private.sessions_r11a() returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501';end if;
 return (select coalesce(jsonb_agg(to_jsonb(x)),'[]') from
 (select id,created_at,refreshed_at,user_agent,ip::text as ip,
 id::text=auth.jwt()->>'session_id' as current_session from auth.sessions
 where user_id=auth.uid() and (not_after is null or not_after>now()) order by created_at desc,id limit 100) x);
end $$;
create or replace function kaoid_private.revoke_session_r11a(p_session uuid,p_others boolean default false) returns boolean
language plpgsql security definer set search_path='' as $$
declare n integer;
begin
 if not kaoid_private.account_active_r9f() then raise exception 'account_restricted' using errcode='42501';end if;
 if p_others is null or (not p_others and p_session is null) then raise exception 'invalid_session';end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 if not p_others and p_session::text=auth.jwt()->>'session_id' then raise exception 'use_sign_out';end if;
 if not p_others and exists(select 1 from auth.sessions where id=p_session and user_id<>auth.uid()) then raise exception 'not_authorized' using errcode='42501';end if;
 delete from auth.refresh_tokens where session_id in (select id from auth.sessions where user_id=auth.uid()
 and id::text<>auth.jwt()->>'session_id' and (p_others or id=p_session));
 delete from auth.sessions where user_id=auth.uid() and id::text<>auth.jwt()->>'session_id' and (p_others or id=p_session);
 get diagnostics n=row_count;
 if n>0 then insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'account.sessions.revoke','profiles',auth.uid(),jsonb_build_object('count',n,'others',p_others)::text);end if;
 return true;
end $$;
create or replace function public.sessions_r11a() returns jsonb language sql set search_path='' as $$select kaoid_private.sessions_r11a();$$;
create or replace function public.revoke_session_r11a(p_session uuid,p_others boolean default false) returns boolean language sql set search_path='' as $$select kaoid_private.revoke_session_r11a(p_session,p_others);$$;
revoke all on function kaoid_private.sessions_r11a(),kaoid_private.revoke_session_r11a(uuid,boolean),public.sessions_r11a(),public.revoke_session_r11a(uuid,boolean) from public,anon;
grant execute on function kaoid_private.sessions_r11a(),kaoid_private.revoke_session_r11a(uuid,boolean),public.sessions_r11a(),public.revoke_session_r11a(uuid,boolean) to authenticated;

CREATE OR REPLACE FUNCTION kaoid_private.can_review_r7c()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$ select kaoid_private.account_active_r9f() and auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and exists(select 1 from public.profiles p where p.id=auth.uid() and p.account_status='active' and p.deleted_at is null and (exists(select 1 from public.company_owners o where o.profile_id=p.id) or exists(select 1 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id where a.profile_id=p.id and a.is_active and r.is_active and r.code='kyc_officer' and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())))); $function$
;
CREATE OR REPLACE FUNCTION kaoid_private.can_read_members_r9a()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select kaoid_private.account_active_r9f() and auth.uid() is not null
 and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
 and exists(select 1 from public.company_owners o join public.profiles p on p.id=o.profile_id
 where o.profile_id=auth.uid() and p.account_status='active' and p.deleted_at is null);
$function$
;
CREATE OR REPLACE FUNCTION kaoid_private.set_account_state_r9f(p_target uuid, p_expected text, p_next text, p_reason text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 if p_next='suspended' then
  delete from auth.refresh_tokens where session_id in (select id from auth.sessions where user_id=p_target);
  delete from auth.sessions where user_id=p_target;
 end if;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'account.'||case when p_next='suspended' then 'suspend' else 'restore' end,'profiles',p_target,
 jsonb_build_object('previous',previous,'next',p_next,'reason',btrim(p_reason))::text);
 return true;
end $function$
;;
