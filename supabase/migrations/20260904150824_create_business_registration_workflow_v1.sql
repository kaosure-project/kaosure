create table if not exists public.business_registrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  business_type text not null default 'registered_business',
  business_name text not null,
  registration_number text not null,
  business_category text not null,
  business_description text,
  document_id uuid references public.identity_documents(id) on delete set null,
  document_status text not null default 'pending',
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  submitted_at timestamptz,
  constraint business_registrations_status_check check (status in ('draft','submitted','under_review','requires_action','approved','rejected')),
  constraint business_registrations_document_status_check check (document_status in ('pending','uploaded','verified','rejected')),
  constraint business_registrations_business_name_check check (length(trim(business_name)) > 0),
  constraint business_registrations_registration_number_check check (length(trim(registration_number)) > 0),
  constraint business_registrations_business_category_check check (length(trim(business_category)) > 0)
);

create index if not exists idx_business_registrations_user_id on public.business_registrations(user_id);
create index if not exists idx_business_registrations_organization_id on public.business_registrations(organization_id);
create unique index if not exists uq_business_registrations_one_active_per_user on public.business_registrations(user_id) where status in ('draft','submitted','under_review','requires_action');

alter table public.business_registrations enable row level security;

drop policy if exists business_registrations_select_own on public.business_registrations;
drop policy if exists business_registrations_insert_own on public.business_registrations;
drop policy if exists business_registrations_update_own on public.business_registrations;
drop policy if exists business_registrations_delete_own on public.business_registrations;

create policy business_registrations_select_own on public.business_registrations for select to authenticated using (user_id = auth.uid());
create policy business_registrations_insert_own on public.business_registrations for insert to authenticated with check (user_id = auth.uid());
create policy business_registrations_update_own on public.business_registrations for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy business_registrations_delete_own on public.business_registrations for delete to authenticated using (user_id = auth.uid());

create or replace function public.set_business_registration_updated_at()
returns trigger language plpgsql security invoker set search_path = public as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_business_registrations_updated_at on public.business_registrations;
create trigger trg_business_registrations_updated_at before update on public.business_registrations for each row execute function public.set_business_registration_updated_at();

create or replace function public.create_business_registration(
  p_business_type text,
  p_business_name text,
  p_registration_number text,
  p_business_category text,
  p_business_description text default null
)
returns public.business_registrations
language plpgsql security definer set search_path = public
as $$
declare v_row public.business_registrations;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if exists (select 1 from public.business_registrations where user_id=auth.uid() and status in ('draft','submitted','under_review','requires_action')) then raise exception 'ACTIVE_BUSINESS_REGISTRATION_EXISTS'; end if;
  insert into public.business_registrations(user_id,business_type,business_name,registration_number,business_category,business_description)
  values(auth.uid(),coalesce(nullif(trim(p_business_type),''),'registered_business'),trim(p_business_name),trim(p_registration_number),trim(p_business_category),nullif(trim(p_business_description),''))
  returning * into v_row;
  return v_row;
end; $$;

create or replace function public.get_current_business_registration()
returns public.business_registrations
language sql security definer set search_path = public
as $$
  select * from public.business_registrations where user_id=auth.uid() order by created_at desc limit 1;
$$;

create or replace function public.get_business_registration(p_registration_id uuid)
returns public.business_registrations
language sql security definer set search_path = public
as $$
  select * from public.business_registrations where id=p_registration_id and user_id=auth.uid();
$$;

create or replace function public.update_business_registration(
  p_registration_id uuid,
  p_business_type text,
  p_business_name text,
  p_registration_number text,
  p_business_category text,
  p_business_description text default null
)
returns public.business_registrations
language plpgsql security definer set search_path = public
as $$
declare v_row public.business_registrations;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  update public.business_registrations
  set business_type=coalesce(nullif(trim(p_business_type),''),'registered_business'), business_name=trim(p_business_name), registration_number=trim(p_registration_number), business_category=trim(p_business_category), business_description=nullif(trim(p_business_description),'')
  where id=p_registration_id and user_id=auth.uid() and status='draft'
  returning * into v_row;
  if v_row.id is null then raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE'; end if;
  return v_row;
end; $$;

create or replace function public.attach_business_registration_document(p_registration_id uuid, p_document_id uuid)
returns public.business_registrations
language plpgsql security definer set search_path = public
as $$
declare v_row public.business_registrations;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (select 1 from public.identity_documents d where d.id=p_document_id and d.owner_id=auth.uid() and d.deleted_at is null) then raise exception 'DOCUMENT_NOT_OWNED'; end if;
  update public.business_registrations
  set document_id=p_document_id, document_status='uploaded'
  where id=p_registration_id and user_id=auth.uid() and status='draft'
  returning * into v_row;
  if v_row.id is null then raise exception 'DRAFT_NOT_FOUND_OR_NOT_EDITABLE'; end if;
  return v_row;
end; $$;

create or replace function public.submit_business_registration(p_registration_id uuid)
returns public.business_registrations
language plpgsql security definer set search_path = public
as $$
declare v_row public.business_registrations; v_org_id uuid;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_row from public.business_registrations where id=p_registration_id and user_id=auth.uid() for update;
  if v_row.id is null then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_row.status <> 'draft' then raise exception 'REGISTRATION_NOT_DRAFT'; end if;
  if v_row.document_id is null then raise exception 'BUSINESS_DOCUMENT_REQUIRED'; end if;
  v_org_id := public.register_organization(v_row.business_name, v_row.business_name, v_row.registration_number, case when v_row.business_type='registered_business' then 'company' else v_row.business_type end, 'TH');
  perform public.initialize_organization_verification(v_org_id);
  update public.business_registrations set organization_id=v_org_id,status='under_review',submitted_at=now() where id=v_row.id returning * into v_row;
  return v_row;
end; $$;

create or replace function public.cancel_business_registration(p_registration_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  update public.business_registrations set status='rejected' where id=p_registration_id and user_id=auth.uid() and status='draft';
  if not found then raise exception 'DRAFT_NOT_FOUND_OR_NOT_CANCELLABLE'; end if;
end; $$;

create or replace function public.refresh_business_registration_status(p_registration_id uuid)
returns public.business_registrations
language plpgsql security definer set search_path = public
as $$
declare v_row public.business_registrations; v_verification_status text;
begin
  if auth.uid() is null then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_row from public.business_registrations where id=p_registration_id and user_id=auth.uid();
  if v_row.id is null then raise exception 'REGISTRATION_NOT_FOUND'; end if;
  if v_row.organization_id is not null then
    select status into v_verification_status from public.organization_verifications where organization_id=v_row.organization_id;
    if v_verification_status='approved' then
      update public.business_registrations set status='approved', document_status=case when document_id is not null then 'verified' else document_status end where id=v_row.id returning * into v_row;
    elsif v_verification_status='rejected' then
      update public.business_registrations set status='rejected' where id=v_row.id returning * into v_row;
    elsif v_verification_status in ('pending','in_review') then
      update public.business_registrations set status='under_review' where id=v_row.id returning * into v_row;
    end if;
  end if;
  return v_row;
end; $$;

grant execute on function public.create_business_registration(text,text,text,text,text) to authenticated;
grant execute on function public.get_current_business_registration() to authenticated;
grant execute on function public.get_business_registration(uuid) to authenticated;
grant execute on function public.update_business_registration(uuid,text,text,text,text,text) to authenticated;
grant execute on function public.attach_business_registration_document(uuid,uuid) to authenticated;
grant execute on function public.submit_business_registration(uuid) to authenticated;
grant execute on function public.cancel_business_registration(uuid) to authenticated;
grant execute on function public.refresh_business_registration_status(uuid) to authenticated;;
