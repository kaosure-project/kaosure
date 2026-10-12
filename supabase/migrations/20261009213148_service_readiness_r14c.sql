create table kaoid_private.service_readiness_r14c (
 id boolean primary key default true check(id),
 sms_enabled boolean not null default false,
 event_email_enabled boolean not null default false,
 changed_at timestamptz not null default now(),
 evidence_reference text
);
alter table kaoid_private.service_readiness_r14c enable row level security;
revoke all on kaoid_private.service_readiness_r14c from public,anon,authenticated;
insert into kaoid_private.service_readiness_r14c(id) values(true);
create function kaoid_private.service_availability_r14c() returns jsonb language plpgsql stable security definer set search_path='' as $$ begin
 if auth.uid() is null or not kaoid_private.account_active_r9f() then raise exception 'session_required' using errcode='42501';end if;
 return (select jsonb_build_object('sms_enabled',sms_enabled,'event_email_enabled',event_email_enabled) from kaoid_private.service_readiness_r14c where id);
end $$;
create function public.service_availability_r14c() returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.service_availability_r14c(); $$;
revoke all on function public.service_availability_r14c(),kaoid_private.service_availability_r14c() from public,anon;
grant execute on function public.service_availability_r14c(),kaoid_private.service_availability_r14c() to authenticated;
-- Hold only application-event emails; Supabase Auth email is separate.
alter function public.claim_mail_r10a() set schema kaoid_private;
alter function kaoid_private.claim_mail_r10a() rename to claim_mail_execute_r14c;
revoke all on function kaoid_private.claim_mail_execute_r14c() from public,anon,authenticated,service_role;
create function kaoid_private.claim_mail_r14c() returns jsonb language plpgsql security definer set search_path='' as $$ begin
 if not coalesce((select event_email_enabled from kaoid_private.service_readiness_r14c where id),false) then return null;end if;
 return kaoid_private.claim_mail_execute_r14c();
end $$;
create function public.claim_mail_r10a() returns jsonb language sql security invoker set search_path='' as $$ select kaoid_private.claim_mail_r14c(); $$;
revoke all on function public.claim_mail_r10a(),kaoid_private.claim_mail_r14c() from public,anon,authenticated;
grant execute on function public.claim_mail_r10a(),kaoid_private.claim_mail_r14c() to service_role;
;
