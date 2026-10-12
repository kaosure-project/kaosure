alter table public.notifications add column if not exists event_key text;
create unique index if not exists notifications_event_key_r10a on public.notifications(event_key) where event_key is not null;
create index if not exists notifications_inbox_r10a on public.notifications(profile_id,created_at desc,id desc) where not is_deleted;
-- In-app content is server-owned. Clients acknowledge only through the RPC below.
revoke insert,update,delete on public.notifications from authenticated,anon;
create table kaoid_private.jobs_r10a(
 id uuid primary key default gen_random_uuid(),kind text not null check(kind in ('email','kyc_precheck')),
 event_key text not null unique,notification_id uuid references public.notifications(id),request_id uuid,
 status text not null default 'pending' check(status in ('pending','processing','done','failed','disabled')),
 attempts int not null default 0,available_at timestamptz not null default now(),
 lease_until timestamptz,lease_token uuid,created_at timestamptz not null default now(),last_error text,
 provider_id text,rule_version text not null default 'manual-v1');
alter table kaoid_private.jobs_r10a enable row level security;
revoke all on kaoid_private.jobs_r10a from public,anon,authenticated;
create index jobs_ready_r10a on kaoid_private.jobs_r10a(kind,status,available_at);

create function kaoid_private.emit_notice_r10a(p_profile uuid,p_key text,p_code text,p_target uuid) returns void
language plpgsql security definer set search_path='' as $$
declare nid uuid;
begin
 insert into public.notifications(profile_id,title,message,notification_type,target_id,event_key)
 values(p_profile,'Kao ID',p_code,'kaoid',p_target,p_key)
 on conflict(event_key) where event_key is not null do nothing returning id into nid;
 if nid is null then return;end if;
 insert into public.notification_logs(notification_id,profile_id,delivery_channel,delivery_status) values(nid,p_profile,'email','pending');
 insert into kaoid_private.jobs_r10a(kind,event_key,notification_id) values('email',p_key,nid) on conflict do nothing;
end $$;
revoke all on function kaoid_private.emit_notice_r10a(uuid,text,text,uuid) from public,anon,authenticated;

create function kaoid_private.notice_event_r10a() returns trigger
language plpgsql security definer set search_path='' as $$
declare uid uuid;code text;
begin
 if tg_table_name='verification_requests' then
  uid:=new.requested_by;
  if tg_op='INSERT' then
   code:='submitted';
   insert into kaoid_private.jobs_r10a(kind,event_key,request_id,status) values('kyc_precheck','precheck:'||new.id,new.id,'disabled') on conflict do nothing;
  elsif new.status is distinct from old.status and new.status in ('approved','rejected') then code:=new.status;
  else return new;end if;
  perform kaoid_private.emit_notice_r10a(uid,'request:'||new.id||':'||code,code,new.id);
 elsif tg_table_name='activity_logs' then
  if new.action in ('kyc.bank.approve','kyc.bank.reject') then
   select profile_id into uid from public.bank_accounts where id=new.target_id;
   code:=case when new.action='kyc.bank.approve' then 'bank_approved' else 'bank_rejected' end;
  elsif new.action in ('account.suspend','account.restore') then
   uid:=new.target_id;code:=case when new.action='account.suspend' then 'suspended' else 'restored' end;
  else return new;end if;
  if uid is not null then perform kaoid_private.emit_notice_r10a(uid,'activity:'||new.id,code,new.target_id);end if;
 end if;return new;
end $$;
revoke all on function kaoid_private.notice_event_r10a() from public,anon,authenticated;
create trigger request_notice_r10a after insert or update of status on public.verification_requests for each row execute function kaoid_private.notice_event_r10a();
create trigger activity_notice_r10a after insert on public.activity_logs for each row execute function kaoid_private.notice_event_r10a();

create function public.kaoid_inbox_r10a(p_before timestamptz default null,p_before_id uuid default null) returns jsonb
language sql security invoker set search_path='' as $$
 select jsonb_build_object('unread',(select count(*) from public.notifications where profile_id=auth.uid() and notification_type='kaoid' and not is_read and not is_deleted),
 'items',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select id,message,is_read,created_at from public.notifications
 where profile_id=auth.uid() and notification_type='kaoid' and not is_deleted and (p_before is null or (created_at,id)<(p_before,p_before_id)) order by created_at desc,id desc limit 30)x));
$$;
create function kaoid_private.read_notice_r10a(p_id uuid) returns boolean
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication_required' using errcode='42501';end if;
 update public.notifications set is_read=true,read_at=coalesce(read_at,now()) where id=p_id and profile_id=auth.uid() and notification_type='kaoid' and not is_deleted;
 return found;
end $$;
create function public.kaoid_read_notice_r10a(p_id uuid) returns boolean language sql security invoker set search_path='' as $$select kaoid_private.read_notice_r10a(p_id);$$;
revoke all on function public.kaoid_inbox_r10a(timestamptz,uuid),public.kaoid_read_notice_r10a(uuid),kaoid_private.read_notice_r10a(uuid) from public,anon;
grant execute on function public.kaoid_inbox_r10a(timestamptz,uuid),public.kaoid_read_notice_r10a(uuid),kaoid_private.read_notice_r10a(uuid) to authenticated;

create function public.claim_mail_r10a() returns jsonb language plpgsql security definer set search_path='' as $$
declare j kaoid_private.jobs_r10a%rowtype; addr text;
begin
 select * into j from kaoid_private.jobs_r10a where kind='email' and attempts<5 and
 (status='pending' and available_at<=now() or status='processing' and lease_until<now())
 and created_at>now()-interval '23 hours' order by created_at for update skip locked limit 1;
 if not found then return null;end if;
 select u.email into addr from public.notifications n join auth.users u on u.id=n.profile_id
 where n.id=j.notification_id and u.email_confirmed_at is not null
 and not exists(select 1 from public.notification_settings s where s.profile_id=u.id and not s.email_enabled);
 if addr is null then
 update kaoid_private.jobs_r10a set status='failed',last_error='recipient_unavailable' where id=j.id;
 update public.notification_logs set delivery_status='failed',error_message='recipient_unavailable' where notification_id=j.notification_id and delivery_channel='email';
 return null;end if;
 update kaoid_private.jobs_r10a set status='processing',attempts=attempts+1,lease_until=now()+interval '2 minutes',lease_token=gen_random_uuid() where id=j.id returning * into j;
 return jsonb_build_object('id',j.id,'token',j.lease_token,'email',addr,'notification_id',j.notification_id);
end $$;
create function public.finish_mail_r10a(p_id uuid,p_token uuid,p_success boolean,p_provider text default null) returns boolean
language plpgsql security definer set search_path='' as $$
declare j kaoid_private.jobs_r10a%rowtype;
begin
 select * into j from kaoid_private.jobs_r10a where id=p_id and lease_token=p_token and status='processing' for update;
 if not found then return false;end if;
 update kaoid_private.jobs_r10a set status=case when p_success then 'done' when attempts>=5 then 'failed' else 'pending' end,
 available_at=now()+interval '5 minutes',lease_until=null,lease_token=null,provider_id=p_provider,
 last_error=case when p_success then null else 'provider_error' end where id=j.id;
 update public.notification_logs set delivery_status=case when p_success then 'sent' else 'failed' end,
 sent_at=case when p_success then now() else null end,error_message=case when p_success then null else 'provider_error' end where notification_id=j.notification_id and delivery_channel='email';
 return true;
end $$;
revoke all on function public.claim_mail_r10a(),public.finish_mail_r10a(uuid,uuid,boolean,text) from public,anon,authenticated;
grant execute on function public.claim_mail_r10a(),public.finish_mail_r10a(uuid,uuid,boolean,text) to service_role;
;
