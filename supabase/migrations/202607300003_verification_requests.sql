-- ============================================================
-- Kao ID
-- Table: verification_requests
-- Description:
-- เก็บคำขอการยืนยันตัวตน (KYC)
-- ============================================================

create table if not exists public.verification_requests (

    id uuid primary key default gen_random_uuid(),

    document_id uuid not null
        references public.identity_documents(id)
        on delete cascade,

    requested_by uuid not null
        references public.profiles(id)
        on delete cascade,

    status text not null,

    submitted_at timestamptz not null default now(),

    reviewed_at timestamptz,

    reviewed_by uuid
        references public.profiles(id),

    rejection_reason text,

    notes text,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()

);

---------------------------------------------------------------
-- Comments
---------------------------------------------------------------

comment on table public.verification_requests
is 'Identity verification (KYC) requests';

comment on column public.verification_requests.document_id
is 'Document submitted for verification';

comment on column public.verification_requests.requested_by
is 'Profile that owns this verification request';

comment on column public.verification_requests.reviewed_by
is 'Administrator who reviewed the request';

---------------------------------------------------------------
-- Indexes
---------------------------------------------------------------

create index if not exists idx_verification_document
on public.verification_requests(document_id);

create index if not exists idx_verification_user
on public.verification_requests(requested_by);

create index if not exists idx_verification_status
on public.verification_requests(status);

---------------------------------------------------------------
-- Trigger
---------------------------------------------------------------

drop trigger if exists trg_verification_requests_updated_at
on public.verification_requests;

create trigger trg_verification_requests_updated_at

before update

on public.verification_requests

for each row

execute function public.update_updated_at_column();

---------------------------------------------------------------
-- RLS
---------------------------------------------------------------

alter table public.verification_requests
enable row level security;

---------------------------------------------------------------
-- Policies
---------------------------------------------------------------

create policy verification_requests_select_own

on public.verification_requests

for select

using (

    requested_by = auth.uid()

);

create policy verification_requests_insert_own

on public.verification_requests

for insert

with check (

    requested_by = auth.uid()

);

create policy verification_requests_update_own

on public.verification_requests

for update

using (

    requested_by = auth.uid()

);

create policy verification_requests_delete_own

on public.verification_requests

for delete

using (

    requested_by = auth.uid()

);