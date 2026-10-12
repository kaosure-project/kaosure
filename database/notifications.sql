-- New events only. Existing inbox and mail outbox remain authoritative.
create function kaoid_private.review_recipients_r14b(p_applicant uuid,p_exclude uuid default null) returns setof uuid
language sql stable security definer set search_path='' as $$
 select p.id from public.profiles p where p.account_status='active' and p.deleted_at is null
 and p.id is distinct from p_applicant and p.id is distinct from p_exclude
 and (exists(select 1 from public.company_owners o where o.profile_id=p.id) or exists(
 select 1 from public.admin_assignments a join public.admin_roles r on r.id=a.role_id
 where a.profile_id=p.id and a.is_active and r.is_active and r.code='kyc_officer'
 and a.starts_at<=now() and (a.expires_at is null or a.expires_at>now())));
$$;
create function kaoid_private.staff_notice_r14b() returns trigger language plpgsql security definer set search_path='' as $$
declare recipient uuid; applicant uuid; target uuid; excluded uuid; code text; event text; ar public.approval_requests%rowtype;
begin
 if tg_table_name='verification_requests' then
  if new.status not in ('pending','under_review') then return new;end if;
  applicant:=new.requested_by;target:=new.id;code:='review_new';event:='request:'||new.id;
 elsif tg_table_name='financial_verifications' then
  if new.status<>'pending' then return new;end if;
  applicant:=new.profile_id;target:=new.id;code:='review_new';event:='bank:'||new.id;
 elsif tg_table_name='approval_histories' then
  if new.event not in ('request_created','rejected') then return new;end if;
  select * into ar from public.approval_requests where id=new.approval_request_id and resource in ('kaoid_review','kaoid_recovery');
  if not found then return new;end if;
  target:=ar.resource_id;
  select requested_by into applicant from public.verification_requests where id=target;
  if applicant is null then select profile_id into applicant from public.financial_verifications where id=target;end if;
  if applicant is null then return new;end if;
  excluded:=case when new.event='request_created' then ar.requested_by else null end;
  code:=case when new.event='request_created' then 'review_second' else 'review_restart' end;
  event:='vote:'||new.id;
 elsif tg_table_name='activity_logs' then
  if new.action not in ('governance.role.assign','governance.role.revoke') then return new;end if;
  select profile_id into recipient from public.admin_assignments where id=new.target_id;
  if recipient is not null then
   code:=case when new.action='governance.role.assign' then 'role_assigned' else 'role_revoked' end;
   perform kaoid_private.emit_notice_r10a(recipient,'staff:'||new.id||':'||recipient,code,new.target_id);
  end if;
  return new;
 else return new;end if;
 for recipient in select * from kaoid_private.review_recipients_r14b(applicant,excluded) loop
  perform kaoid_private.emit_notice_r10a(recipient,'staff:'||event||':'||recipient,code,target);
 end loop;
 return new;
end $$;
revoke all on function kaoid_private.review_recipients_r14b(uuid,uuid),kaoid_private.staff_notice_r14b() from public,anon,authenticated;
create trigger staff_request_r14b after insert on public.verification_requests for each row execute function kaoid_private.staff_notice_r14b();
create trigger staff_bank_r14b after insert on public.financial_verifications for each row execute function kaoid_private.staff_notice_r14b();
create trigger staff_vote_r14b after insert on public.approval_histories for each row execute function kaoid_private.staff_notice_r14b();
create trigger staff_role_r14b after insert on public.activity_logs for each row execute function kaoid_private.staff_notice_r14b();
