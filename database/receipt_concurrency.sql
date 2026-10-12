-- Shared authorization lock permits distinct member receipts concurrently.
-- Owner disable/report update requires an exclusive row lock and waits for accepted work.
create or replace function kaoid_private.partner_receive_r12b(p_id uuid,p_environment text,p_event text,p_capability text,p_hash text) returns uuid language plpgsql security definer set search_path='' as $$
declare p kaoid_private.partners_r12b%rowtype;r kaoid_private.partner_inbox_r12b%rowtype;new_id uuid;
begin
 select * into p from kaoid_private.partners_r12b where id=p_id for share;
 if not found or p.environment is distinct from p_environment or p.approval<>'approved' or not p.enabled or not kaoid_private.partner_ready_r12b(p_id) or p_capability is null or not(p_capability=any(p.capabilities)) then raise exception 'partner_not_enabled' using errcode='42501';end if;
 insert into kaoid_private.partner_inbox_r12b(partner_id,event_id,capability,payload_hash) values(p_id,p_event,p_capability,p_hash) on conflict(partner_id,event_id) do nothing returning id into new_id;
 if new_id is not null then return new_id;end if;
 select * into r from kaoid_private.partner_inbox_r12b where partner_id=p_id and event_id=p_event;
 if not found or r.payload_hash is distinct from p_hash or r.capability is distinct from p_capability then raise exception 'event_conflict' using errcode='23505';end if;
 return r.id;
end $$;
