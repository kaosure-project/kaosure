-- Owner-controlled multi-provider registry. No funds movement.
create table kaoid_private.partners_r12b (
 id uuid primary key default gen_random_uuid(), code text not null check(code ~ '^[a-z][a-z0-9_-]{1,39}$'),
 name text not null check(length(btrim(name)) between 2 and 120),
 environment text not null check(environment in ('sandbox','live')),
 capabilities text[] not null check(cardinality(capabilities)>0 and capabilities <@ array['balance','payment','refund','payout','topup']::text[]),
 approval text not null default 'pending' check(approval in ('pending','approved','rejected','disabled')),
 enabled boolean not null default false, revision integer not null default 1,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(code,environment),check(not enabled or approval='approved')
);
create table kaoid_private.partner_readiness_r12b (
 partner_id uuid primary key references kaoid_private.partners_r12b(id),
 adapter_version text not null, credentials_ready boolean not null, tests_passed boolean not null,
 evidence_ref text not null check(length(evidence_ref) between 3 and 200),
 capabilities text[] not null, checked_at timestamptz not null default now(),
 expires_at timestamptz not null, check(expires_at>checked_at)
);
create table kaoid_private.partner_history_r12b (
 id bigint generated always as identity primary key, partner_id uuid not null references kaoid_private.partners_r12b(id),
 action text not null, actor_id uuid, actor_role text not null check(actor_role in ('Owner','system')),
 reason text not null, revision integer not null, created_at timestamptz not null default now(),
 check((actor_role='Owner' and actor_id is not null) or (actor_role='system' and actor_id is null))
);
create index on kaoid_private.partner_history_r12b(partner_id,id desc);
create table kaoid_private.partner_inbox_r12b (
 id uuid primary key default gen_random_uuid(), partner_id uuid not null references kaoid_private.partners_r12b(id),
 event_id text not null check(length(event_id) between 1 and 200),
 capability text not null, payload_hash text not null check(payload_hash ~ '^[0-9a-f]{64}$'),
 received_at timestamptz not null default now(),unique(partner_id,event_id)
);
alter table kaoid_private.partners_r12b enable row level security;
alter table kaoid_private.partner_readiness_r12b enable row level security;
alter table kaoid_private.partner_history_r12b enable row level security;
alter table kaoid_private.partner_inbox_r12b enable row level security;
revoke all on kaoid_private.partners_r12b,kaoid_private.partner_readiness_r12b,kaoid_private.partner_history_r12b,kaoid_private.partner_inbox_r12b from public,anon,authenticated;

create function kaoid_private.partner_owner_r12b(p_user uuid) returns void language plpgsql security definer set search_path='' as $$
begin if auth.uid() is null or auth.uid() is distinct from p_user or not kaoid_private.can_read_members_r9a() then raise exception 'partner_owner_required' using errcode='42501';end if;end $$;
create function kaoid_private.partner_ready_r12b(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from kaoid_private.partner_readiness_r12b r join kaoid_private.partners_r12b p on p.id=r.partner_id where p.id=p_id and r.credentials_ready and r.tests_passed and r.expires_at>now() and p.capabilities <@ r.capabilities);
$$;
create function kaoid_private.partner_list_r12b(p_user uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 perform kaoid_private.partner_owner_r12b(p_user);
 select coalesce(jsonb_agg(to_jsonb(p)||jsonb_build_object('ready',kaoid_private.partner_ready_r12b(p.id),'connected',p.enabled and kaoid_private.partner_ready_r12b(p.id),'readiness',(select jsonb_build_object('adapter_version',r.adapter_version,'checked_at',r.checked_at,'expires_at',r.expires_at) from kaoid_private.partner_readiness_r12b r where r.partner_id=p.id),'history',(select coalesce(jsonb_agg(to_jsonb(h) order by h.id desc),'[]'::jsonb) from (select * from kaoid_private.partner_history_r12b where partner_id=p.id order by id desc limit 20)h)) order by p.created_at desc,p.id),'[]'::jsonb) into result from kaoid_private.partners_r12b p;
 return result;
end $$;
create function kaoid_private.partner_create_r12b(p_user uuid,p_code text,p_name text,p_environment text,p_capabilities text[]) returns uuid language plpgsql security definer set search_path='' as $$
declare found_row kaoid_private.partners_r12b%rowtype; new_id uuid; caps text[];
begin
 perform kaoid_private.partner_owner_r12b(p_user);
 p_code:=lower(btrim(p_code));p_name:=btrim(p_name);
 select array_agg(distinct c order by c) into caps from unnest(p_capabilities)c;
 if p_code is null or p_name is null or p_environment is null or caps is null then raise exception 'invalid_partner' using errcode='22023';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_code||':'||p_environment,0));
 select * into found_row from kaoid_private.partners_r12b where code=p_code and environment=p_environment;
 if found then
  if found_row.name=p_name and found_row.capabilities=caps then return found_row.id;end if;
  raise exception 'partner_already_exists' using errcode='23505';
 end if;
 insert into kaoid_private.partners_r12b(code,name,environment,capabilities) values(p_code,p_name,p_environment,caps) returning id into new_id;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_id,actor_role,reason,revision) values(new_id,'create',auth.uid(),'Owner','',1);
 return new_id;
end $$;
create function kaoid_private.partner_decide_r12b(p_user uuid,p_id uuid,p_revision integer,p_action text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare p kaoid_private.partners_r12b%rowtype; next_approval text; next_enabled boolean;
begin
 perform kaoid_private.partner_owner_r12b(p_user);
 if p_reason is null or length(btrim(p_reason)) not between 3 and 500 then raise exception 'reason_required' using errcode='22023';end if;
 select * into p from kaoid_private.partners_r12b where id=p_id for update;
 if not found then raise exception 'partner_not_found' using errcode='22023';end if;
 if p.revision is distinct from p_revision then raise exception 'partner_changed_reload' using errcode='40001';end if;
 next_approval:=p.approval;next_enabled:=p.enabled;
 if p_action='approve' and p.approval='pending' then next_approval:='approved';next_enabled:=false;
 elsif p_action='reject' and p.approval='pending' then next_approval:='rejected';next_enabled:=false;
 elsif p_action='disable' and p.approval='approved' then next_approval:='disabled';next_enabled:=false;
 elsif p_action='resubmit' and p.approval in ('rejected','disabled') then next_approval:='pending';next_enabled:=false;
 elsif p_action='enable' and p.approval='approved' and not p.enabled then
  if not kaoid_private.partner_ready_r12b(p.id) then raise exception 'partner_not_ready' using errcode='22023';end if;
  next_enabled:=true;
 else raise exception 'invalid_partner_transition' using errcode='22023';end if;
 update kaoid_private.partners_r12b set approval=next_approval,enabled=next_enabled,revision=revision+1,updated_at=now() where id=p.id;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_id,actor_role,reason,revision) values(p.id,p_action,auth.uid(),'Owner',btrim(p_reason),p.revision+1);
end $$;
-- Server reports must be generated from real adapter/config/test evidence, never browser booleans.
create function kaoid_private.partner_report_r12b(p_id uuid,p_adapter text,p_credentials boolean,p_tests boolean,p_capabilities text[],p_evidence text,p_expires timestamptz) returns void language plpgsql security definer set search_path='' as $$
declare rev integer;
begin
 if p_adapter is null or length(btrim(p_adapter)) not between 1 and 100 or p_expires is null or p_expires<=now() or p_expires>now()+interval '30 days' or p_capabilities is null or not(p_capabilities <@ array['balance','payment','refund','payout','topup']::text[]) then raise exception 'invalid_readiness_report';end if;
 update kaoid_private.partners_r12b set enabled=false,revision=revision+1,updated_at=now() where id=p_id returning revision into rev;
 if not found then raise exception 'partner_not_found';end if;
 insert into kaoid_private.partner_readiness_r12b(partner_id,adapter_version,credentials_ready,tests_passed,capabilities,evidence_ref,expires_at) values(p_id,p_adapter,p_credentials,p_tests,p_capabilities,p_evidence,p_expires)
 on conflict(partner_id) do update set adapter_version=excluded.adapter_version,credentials_ready=excluded.credentials_ready,tests_passed=excluded.tests_passed,capabilities=excluded.capabilities,evidence_ref=excluded.evidence_ref,checked_at=now(),expires_at=excluded.expires_at;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_role,reason,revision) values(p_id,'readiness','system',p_evidence,rev);
end $$;
-- Call only AFTER provider-specific signature, freshness and payload validation.
-- This inbox deduplicates receipts; it does not settle or credit any wallet.
create function kaoid_private.partner_receive_r12b(p_id uuid,p_environment text,p_event text,p_capability text,p_hash text) returns uuid language plpgsql security definer set search_path='' as $$
declare p kaoid_private.partners_r12b%rowtype; r kaoid_private.partner_inbox_r12b%rowtype;new_id uuid;
begin
 select * into p from kaoid_private.partners_r12b where id=p_id for update;
 if not found or p.environment is distinct from p_environment or p.approval<>'approved' or not p.enabled or not kaoid_private.partner_ready_r12b(p_id) or p_capability is null or not(p_capability=any(p.capabilities)) then raise exception 'partner_not_enabled' using errcode='42501';end if;
 select * into r from kaoid_private.partner_inbox_r12b where partner_id=p_id and event_id=p_event;
 if found then
  if r.payload_hash is distinct from p_hash or r.capability is distinct from p_capability then raise exception 'event_conflict' using errcode='23505';end if;
  return r.id;
 end if;
 insert into kaoid_private.partner_inbox_r12b(partner_id,event_id,capability,payload_hash) values(p_id,p_event,p_capability,p_hash) returning id into new_id;return new_id;
end $$;

revoke all on function kaoid_private.partner_list_r12b(uuid) from public,anon,authenticated;
grant execute on function kaoid_private.partner_list_r12b(uuid) to authenticated;
create function public.partner_list_r12b(p_user uuid) returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.partner_list_r12b(p_user); $$;
revoke all on function public.partner_list_r12b(uuid) from public,anon,authenticated;
grant execute on function public.partner_list_r12b(uuid) to authenticated;

revoke all on function kaoid_private.partner_create_r12b(uuid,text,text,text,text[]) from public,anon,authenticated;
grant execute on function kaoid_private.partner_create_r12b(uuid,text,text,text,text[]) to authenticated;
create function public.partner_create_r12b(p_user uuid,p_code text,p_name text,p_environment text,p_capabilities text[]) returns uuid language sql security invoker set search_path='' as $$ select kaoid_private.partner_create_r12b(p_user,p_code,p_name,p_environment,p_capabilities); $$;
revoke all on function public.partner_create_r12b(uuid,text,text,text,text[]) from public,anon,authenticated;
grant execute on function public.partner_create_r12b(uuid,text,text,text,text[]) to authenticated;

revoke all on function kaoid_private.partner_decide_r12b(uuid,uuid,integer,text,text) from public,anon,authenticated;
grant execute on function kaoid_private.partner_decide_r12b(uuid,uuid,integer,text,text) to authenticated;
create function public.partner_decide_r12b(p_user uuid,p_id uuid,p_revision integer,p_action text,p_reason text) returns void language sql security invoker set search_path='' as $$ select kaoid_private.partner_decide_r12b(p_user,p_id,p_revision,p_action,p_reason); $$;
revoke all on function public.partner_decide_r12b(uuid,uuid,integer,text,text) from public,anon,authenticated;
grant execute on function public.partner_decide_r12b(uuid,uuid,integer,text,text) to authenticated;

revoke all on function kaoid_private.partner_report_r12b(uuid,text,boolean,boolean,text[],text,timestamptz) from public,anon,authenticated;
grant execute on function kaoid_private.partner_report_r12b(uuid,text,boolean,boolean,text[],text,timestamptz) to service_role;
create function public.partner_report_r12b(p_id uuid,p_adapter text,p_credentials boolean,p_tests boolean,p_capabilities text[],p_evidence text,p_expires timestamptz) returns void language sql security invoker set search_path='' as $$ select kaoid_private.partner_report_r12b(p_id,p_adapter,p_credentials,p_tests,p_capabilities,p_evidence,p_expires); $$;
revoke all on function public.partner_report_r12b(uuid,text,boolean,boolean,text[],text,timestamptz) from public,anon,authenticated;
grant execute on function public.partner_report_r12b(uuid,text,boolean,boolean,text[],text,timestamptz) to service_role;

revoke all on function kaoid_private.partner_receive_r12b(uuid,text,text,text,text) from public,anon,authenticated;
grant execute on function kaoid_private.partner_receive_r12b(uuid,text,text,text,text) to service_role;
create function public.partner_receive_r12b(p_id uuid,p_environment text,p_event text,p_capability text,p_hash text) returns uuid language sql security invoker set search_path='' as $$ select kaoid_private.partner_receive_r12b(p_id,p_environment,p_event,p_capability,p_hash); $$;
revoke all on function public.partner_receive_r12b(uuid,text,text,text,text) from public,anon,authenticated;
grant execute on function public.partner_receive_r12b(uuid,text,text,text,text) to service_role;
revoke all on function kaoid_private.partner_owner_r12b(uuid),kaoid_private.partner_ready_r12b(uuid) from public,anon,authenticated;
