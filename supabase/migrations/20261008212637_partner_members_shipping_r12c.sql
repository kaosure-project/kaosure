-- Extend the existing registry; do not create a second approval system.
alter table kaoid_private.partners_r12b add column kind text not null default 'finance' check(kind in ('finance','shipping'));
alter table kaoid_private.partners_r12b drop constraint partners_r12b_capabilities_check;
alter table kaoid_private.partners_r12b add constraint partner_scopes_r12c check(cardinality(capabilities)>0 and ((kind='finance' and capabilities <@ array['balance','payment','refund','payout','topup']::text[]) or (kind='shipping' and capabilities <@ array['quote','shipment','tracking','cancel_shipment']::text[])));
create function kaoid_private.partner_create_r12c(p_user uuid,p_code text,p_name text,p_environment text,p_capabilities text[],p_kind text) returns uuid language plpgsql security definer set search_path='' as $$
declare r kaoid_private.partners_r12b%rowtype; caps text[]; new_id uuid;
begin
 perform kaoid_private.partner_owner_r12b(p_user);
 p_code:=lower(btrim(p_code));p_name:=btrim(p_name);
 select array_agg(distinct c order by c) into caps from unnest(p_capabilities)c;
 if p_code is null or p_name is null or p_environment is null or p_kind is null or caps is null then raise exception 'invalid_partner';end if;
 perform pg_advisory_xact_lock(hashtextextended(p_code||':'||p_environment,0));
 select * into r from kaoid_private.partners_r12b where code=p_code and environment=p_environment;
 if found then
 if r.name=p_name and r.capabilities=caps and r.kind=p_kind then return r.id;end if;
 raise exception 'partner_already_exists' using errcode='23505';end if;
 insert into kaoid_private.partners_r12b(code,name,environment,capabilities,kind) values(p_code,p_name,p_environment,caps,p_kind) returning id into new_id;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_id,actor_role,reason,revision) values(new_id,'create',auth.uid(),'Owner','',1);
 return new_id;
end $$;
create table kaoid_private.wallet_links_r12c (
 id uuid primary key default gen_random_uuid(), profile_id uuid not null references public.profiles(id) on delete restrict,
 partner_id uuid not null references kaoid_private.partners_r12b(id), external_ref text not null check(length(btrim(external_ref)) between 1 and 200),
 currency text not null default 'THB' check(currency='THB'),created_at timestamptz not null default now(),
 unique(partner_id,external_ref),unique(partner_id,profile_id,currency)
);
create index on kaoid_private.wallet_links_r12c(profile_id);
create table kaoid_private.wallet_snapshots_r12c (
 link_id uuid primary key references kaoid_private.wallet_links_r12c(id),sequence bigint not null check(sequence>=0),
 available numeric(20,2) not null check(available>=0),held numeric(20,2) not null check(held>=0),pending numeric(20,2) not null check(pending>=0),
 observed_at timestamptz not null,received_at timestamptz not null default now(),receipt_id uuid not null unique references kaoid_private.partner_inbox_r12b(id)
);
create table kaoid_private.wallet_updates_r12c (
 receipt_id uuid primary key references kaoid_private.partner_inbox_r12b(id),link_id uuid not null references kaoid_private.wallet_links_r12c(id),
 sequence bigint not null,outcome text not null check(outcome in ('applied','older')),normalized jsonb not null,created_at timestamptz not null default now()
);
create index on kaoid_private.wallet_updates_r12c(link_id,created_at desc);
alter table kaoid_private.wallet_links_r12c enable row level security;
alter table kaoid_private.wallet_snapshots_r12c enable row level security;
alter table kaoid_private.wallet_updates_r12c enable row level security;
revoke all on kaoid_private.wallet_links_r12c,kaoid_private.wallet_snapshots_r12c,kaoid_private.wallet_updates_r12c from public,anon,authenticated;
-- Server-only: requires verified provider account ownership before invocation.
create function kaoid_private.wallet_link_r12c(p_partner uuid,p_environment text,p_profile uuid,p_external text) returns uuid language plpgsql security definer set search_path='' as $$
declare p kaoid_private.partners_r12b%rowtype;r kaoid_private.wallet_links_r12c%rowtype;new_id uuid;
begin
 select * into p from kaoid_private.partners_r12b where id=p_partner for update;
 if not found or p.kind<>'finance' or p.environment is distinct from p_environment or p.approval<>'approved' or not p.enabled or not kaoid_private.partner_ready_r12b(p.id) or not('balance'=any(p.capabilities)) then raise exception 'partner_not_enabled' using errcode='42501';end if;
 perform 1 from public.profiles where id=p_profile for update;
 if not exists(select 1 from public.profiles where id=p_profile and account_status='active' and deleted_at is null) then raise exception 'member_unavailable' using errcode='42501';end if;
 p_external:=btrim(p_external);
 select * into r from kaoid_private.wallet_links_r12c where partner_id=p.id and profile_id=p_profile and currency='THB';
 if found then if r.external_ref=p_external then return r.id;end if;raise exception 'wallet_binding_conflict' using errcode='23505';end if;
 insert into kaoid_private.wallet_links_r12c(profile_id,partner_id,external_ref) values(p_profile,p.id,p_external) returning id into new_id;
 return new_id;
end $$;
-- Verified adapter supplies an ordered, complete snapshot; never a browser balance.
create function kaoid_private.wallet_sync_r12c(p_partner uuid,p_environment text,p_external text,p_event text,p_hash text,p_sequence bigint,p_available numeric,p_held numeric,p_pending numeric,p_observed timestamptz) returns text language plpgsql security definer set search_path='' as $$
declare l kaoid_private.wallet_links_r12c%rowtype;s kaoid_private.wallet_snapshots_r12c%rowtype;u kaoid_private.wallet_updates_r12c%rowtype;receipt uuid;data jsonb;outcome text;
begin
 if p_sequence is null or p_sequence<0 or p_observed is null or p_observed>now()+interval '5 minutes' or p_available is null or p_held is null or p_pending is null or p_available<0 or p_held<0 or p_pending<0 or p_available::text in ('NaN','Infinity','-Infinity') or p_held::text in ('NaN','Infinity','-Infinity') or p_pending::text in ('NaN','Infinity','-Infinity') or p_available<>round(p_available,2) or p_held<>round(p_held,2) or p_pending<>round(p_pending,2) then raise exception 'invalid_wallet_snapshot' using errcode='22023';end if;
 receipt:=kaoid_private.partner_receive_r12b(p_partner,p_environment,p_event,'balance',p_hash);
 select * into l from kaoid_private.wallet_links_r12c where partner_id=p_partner and external_ref=p_external for update;
 if not found then raise exception 'wallet_binding_missing' using errcode='22023';end if;
 data:=jsonb_build_object('sequence',p_sequence,'available',p_available,'held',p_held,'pending',p_pending,'observed_at',p_observed);
 select * into u from kaoid_private.wallet_updates_r12c where receipt_id=receipt;
 if found then if u.link_id<>l.id or u.normalized<>data then raise exception 'wallet_event_conflict' using errcode='23505';end if;return 'duplicate';end if;
 select * into s from kaoid_private.wallet_snapshots_r12c where link_id=l.id;
 if found and p_sequence=s.sequence then raise exception 'wallet_sequence_conflict' using errcode='23505';end if;
 if found and (p_sequence<s.sequence or p_observed<s.observed_at) then outcome:='older';
 else
 outcome:='applied';
 insert into kaoid_private.wallet_snapshots_r12c(link_id,sequence,available,held,pending,observed_at,receipt_id) values(l.id,p_sequence,p_available,p_held,p_pending,p_observed,receipt)
 on conflict(link_id) do update set sequence=excluded.sequence,available=excluded.available,held=excluded.held,pending=excluded.pending,observed_at=excluded.observed_at,received_at=now(),receipt_id=excluded.receipt_id;
 end if;
 insert into kaoid_private.wallet_updates_r12c(receipt_id,link_id,sequence,outcome,normalized) values(receipt,l.id,p_sequence,outcome,data);
 return outcome;
end $$;
create function kaoid_private.linked_wallets_r12c(p_user uuid,p_profile uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare target uuid:=coalesce(p_profile,auth.uid());owner boolean; result jsonb;
begin
 if auth.uid() is null or auth.uid() is distinct from p_user or not kaoid_private.account_active_r9f() then raise exception 'wallet_access_denied' using errcode='42501';end if;
 owner:=kaoid_private.can_read_members_r9a();
 if target<>auth.uid() and not owner then raise exception 'wallet_access_denied' using errcode='42501';end if;
 if not exists(select 1 from public.profiles where id=target) then raise exception 'member_missing' using errcode='22023';end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',l.id,'partner',p.name,'environment',p.environment,'currency',l.currency,'reference',case when owner then l.external_ref else '…'||right(l.external_ref,4) end,'connected',p.enabled and p.approval='approved' and kaoid_private.partner_ready_r12b(p.id),
 'snapshot',case when s.link_id is null then null else jsonb_build_object('available',s.available::text,'held',s.held::text,'pending',s.pending::text,'observed_at',s.observed_at,'received_at',s.received_at,'stale',s.observed_at<now()-interval '30 minutes') end,
 'updates',case when owner then (select coalesce(jsonb_agg(to_jsonb(t) order by t.created_at desc),'[]'::jsonb) from (select receipt_id,sequence,outcome,created_at from kaoid_private.wallet_updates_r12c where link_id=l.id order by created_at desc,receipt_id desc limit 20)t) else '[]'::jsonb end) order by l.created_at,l.id),'[]'::jsonb) into result
 from kaoid_private.wallet_links_r12c l join kaoid_private.partners_r12b p on p.id=l.partner_id left join kaoid_private.wallet_snapshots_r12c s on s.link_id=l.id where l.profile_id=target and (owner or p.environment='live');
 return result;
end $$;
create or replace function kaoid_private.partner_report_r12b(p_id uuid,p_adapter text,p_credentials boolean,p_tests boolean,p_capabilities text[],p_evidence text,p_expires timestamptz) returns void language plpgsql security definer set search_path='' as $$
declare rev integer;
begin
 if p_adapter is null or length(btrim(p_adapter)) not between 1 and 100 or p_expires is null or p_expires<=now() or p_expires>now()+interval '30 days' or p_capabilities is null or not(p_capabilities <@ array['balance','payment','refund','payout','topup','quote','shipment','tracking','cancel_shipment']::text[]) then raise exception 'invalid_readiness_report';end if;
 if not exists(select 1 from kaoid_private.partners_r12b where id=p_id and p_capabilities <@ capabilities) then raise exception 'readiness_scope_mismatch';end if;
 update kaoid_private.partners_r12b set enabled=false,revision=revision+1,updated_at=now() where id=p_id returning revision into rev;
 if not found then raise exception 'partner_not_found';end if;
 insert into kaoid_private.partner_readiness_r12b(partner_id,adapter_version,credentials_ready,tests_passed,capabilities,evidence_ref,expires_at) values(p_id,p_adapter,p_credentials,p_tests,p_capabilities,p_evidence,p_expires)
 on conflict(partner_id) do update set adapter_version=excluded.adapter_version,credentials_ready=excluded.credentials_ready,tests_passed=excluded.tests_passed,capabilities=excluded.capabilities,evidence_ref=excluded.evidence_ref,checked_at=now(),expires_at=excluded.expires_at;
 insert into kaoid_private.partner_history_r12b(partner_id,action,actor_role,reason,revision) values(p_id,'readiness','system',p_evidence,rev);
end $$;

revoke all on function kaoid_private.partner_create_r12c(uuid,text,text,text,text[],text) from public,anon,authenticated;
grant execute on function kaoid_private.partner_create_r12c(uuid,text,text,text,text[],text) to authenticated;
create function public.partner_create_r12c(p_user uuid,p_code text,p_name text,p_environment text,p_capabilities text[],p_kind text) returns uuid language sql security invoker set search_path='' as $$select kaoid_private.partner_create_r12c(p_user,p_code,p_name,p_environment,p_capabilities,p_kind);$$;
revoke all on function public.partner_create_r12c(uuid,text,text,text,text[],text) from public,anon,authenticated;
grant execute on function public.partner_create_r12c(uuid,text,text,text,text[],text) to authenticated;

revoke all on function kaoid_private.wallet_link_r12c(uuid,text,uuid,text) from public,anon,authenticated;
grant execute on function kaoid_private.wallet_link_r12c(uuid,text,uuid,text) to service_role;
create function public.wallet_link_r12c(p_partner uuid,p_environment text,p_profile uuid,p_external text) returns uuid language sql security invoker set search_path='' as $$select kaoid_private.wallet_link_r12c(p_partner,p_environment,p_profile,p_external);$$;
revoke all on function public.wallet_link_r12c(uuid,text,uuid,text) from public,anon,authenticated;
grant execute on function public.wallet_link_r12c(uuid,text,uuid,text) to service_role;

revoke all on function kaoid_private.wallet_sync_r12c(uuid,text,text,text,text,bigint,numeric,numeric,numeric,timestamptz) from public,anon,authenticated;
grant execute on function kaoid_private.wallet_sync_r12c(uuid,text,text,text,text,bigint,numeric,numeric,numeric,timestamptz) to service_role;
create function public.wallet_sync_r12c(p_partner uuid,p_environment text,p_external text,p_event text,p_hash text,p_sequence bigint,p_available numeric,p_held numeric,p_pending numeric,p_observed timestamptz) returns text language sql security invoker set search_path='' as $$select kaoid_private.wallet_sync_r12c(p_partner,p_environment,p_external,p_event,p_hash,p_sequence,p_available,p_held,p_pending,p_observed);$$;
revoke all on function public.wallet_sync_r12c(uuid,text,text,text,text,bigint,numeric,numeric,numeric,timestamptz) from public,anon,authenticated;
grant execute on function public.wallet_sync_r12c(uuid,text,text,text,text,bigint,numeric,numeric,numeric,timestamptz) to service_role;

revoke all on function kaoid_private.linked_wallets_r12c(uuid,uuid) from public,anon,authenticated;
grant execute on function kaoid_private.linked_wallets_r12c(uuid,uuid) to authenticated;
create function public.linked_wallets_r12c(p_user uuid,p_profile uuid) returns jsonb language sql security invoker set search_path='' as $$select kaoid_private.linked_wallets_r12c(p_user,p_profile);$$;
revoke all on function public.linked_wallets_r12c(uuid,uuid) from public,anon,authenticated;
grant execute on function public.linked_wallets_r12c(uuid,uuid) to authenticated;

-- Prevent account closure while partner balances/obligations have not been reconciled.
do $migration$
declare body text;
begin
 body:=pg_get_functiondef('kaoid_private.closure_blockers_r10d(uuid)'::regprocedure);
 if position('return blockers;' in body)=0 then raise exception 'closure_function_changed';end if;
 body:=replace(body,'return blockers;', $replacement$
 if exists(select 1 from kaoid_private.wallet_links_r12c where profile_id=u) then
 blockers:=blockers||jsonb_build_array(jsonb_build_object('code','service_history','table','partner_wallet','count',1));end if;
 return blockers;$replacement$);
 execute body;
end $migration$;
;
