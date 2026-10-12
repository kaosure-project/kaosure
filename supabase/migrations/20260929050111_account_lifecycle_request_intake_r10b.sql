create table kaoid_private.lifecycle_requests_r10b (
 id uuid primary key default gen_random_uuid(),profile_id uuid not null references public.profiles(id),
 kind text not null check(kind in ('closure','recovery')),
 status text not null default 'pending' check(status in ('pending','cancelled','approved','rejected')),
 reason text not null check(length(btrim(reason)) between 3 and 1000),
 created_at timestamptz not null default now(),updated_at timestamptz not null default now());
alter table kaoid_private.lifecycle_requests_r10b enable row level security;
revoke all on kaoid_private.lifecycle_requests_r10b from public,anon,authenticated;
create unique index lifecycle_pending_r10b on kaoid_private.lifecycle_requests_r10b(profile_id) where status='pending';
create function kaoid_private.lifecycle_snapshot_r10b() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 select account_status into s from public.profiles where id=u and deleted_at is null;
 if s is null then raise exception 'account_unavailable';end if;
 return jsonb_build_object('account_status',s,'owner',exists(select 1 from public.company_owners where profile_id=u),
 'requests',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select id,kind,status,reason,created_at from kaoid_private.lifecycle_requests_r10b where profile_id=u order by created_at desc,id desc limit 20)x));
end $$;
create function kaoid_private.lifecycle_submit_r10b(p_kind text,p_reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();s text;r uuid;k text;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 if p_kind is null or p_kind not in ('closure','recovery') or length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'invalid_request';end if;
 select account_status into s from public.profiles where id=u and deleted_at is null for update;
 if s is null or exists(select 1 from public.company_owners where profile_id=u) then raise exception 'account_unavailable' using errcode='42501';end if;
 if (p_kind='closure' and s<>'active') or (p_kind='recovery' and s<>'closed') then raise exception 'account_state_changed';end if;
 select id,kind into r,k from kaoid_private.lifecycle_requests_r10b where profile_id=u and status='pending';
 if found then if k=p_kind then return r;else raise exception 'request_pending';end if;end if;
 insert into kaoid_private.lifecycle_requests_r10b(profile_id,kind,reason) values(u,p_kind,btrim(p_reason)) returning id into r;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(u,'account.request.'||p_kind,'lifecycle_requests_r10b',r,'Request received; no account or KYC state changed');
 perform kaoid_private.emit_notice_r10a(u,'lifecycle:'||r,'lifecycle_requested',r);
 return r;
end $$;
create function kaoid_private.lifecycle_cancel_r10b(p_id uuid) returns boolean language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid();r kaoid_private.lifecycle_requests_r10b%rowtype;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required' using errcode='42501';end if;
 perform 1 from public.profiles where id=u for update;
 select * into r from kaoid_private.lifecycle_requests_r10b where id=p_id and profile_id=u for update;
 if not found then raise exception 'request_unavailable' using errcode='42501';end if;
 if r.status='cancelled' then return true;end if;
 if r.status<>'pending' then raise exception 'request_already_processed';end if;
 update kaoid_private.lifecycle_requests_r10b set status='cancelled',updated_at=now() where id=r.id;
 insert into public.activity_logs(profile_id,action,target_table,target_id,description) values(u,'account.request.cancel','lifecycle_requests_r10b',r.id,'Cancelled by applicant');
 return true;
end $$;
create function public.lifecycle_snapshot_r10b() returns jsonb language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_snapshot_r10b();$$;
create function public.lifecycle_submit_r10b(p_kind text,p_reason text) returns uuid language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_submit_r10b(p_kind,p_reason);$$;
create function public.lifecycle_cancel_r10b(p_id uuid) returns boolean language sql security invoker set search_path='' as $$select kaoid_private.lifecycle_cancel_r10b(p_id);$$;
revoke all on function kaoid_private.lifecycle_snapshot_r10b(),kaoid_private.lifecycle_submit_r10b(text,text),kaoid_private.lifecycle_cancel_r10b(uuid),public.lifecycle_snapshot_r10b(),public.lifecycle_submit_r10b(text,text),public.lifecycle_cancel_r10b(uuid) from public,anon;
grant execute on function kaoid_private.lifecycle_snapshot_r10b(),kaoid_private.lifecycle_submit_r10b(text,text),kaoid_private.lifecycle_cancel_r10b(uuid),public.lifecycle_snapshot_r10b(),public.lifecycle_submit_r10b(text,text),public.lifecycle_cancel_r10b(uuid) to authenticated;
