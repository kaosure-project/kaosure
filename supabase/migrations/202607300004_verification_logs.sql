-- ============================================================
-- Kao ID
-- Table: verification_logs
-- Description:
-- เก็บประวัติการดำเนินการของคำขอ KYC
-- ============================================================

create table if not exists public.verification_logs (

    id uuid primary key default gen_random_uuid(),

    verification_request_id uuid not null
        references public.verification_requests(id)
        on delete cascade,

    action text not null,

    old_status text,

    new_status text,

    performed_by uuid
        references public.profiles(id),

    notes text,

    created_at timestamptz not null default now()

);

---------------------------------------------------------------
-- Comments
---------------------------------------------------------------

comment on table public.verification_logs
is 'Audit trail for identity verification requests';

comment on column public.verification_logs.verification_request_id
is 'Verification request being tracked';

comment on column public.verification_logs.action
is 'Action performed (submit, review, approve, reject, etc.)';

---------------------------------------------------------------
-- Indexes
---------------------------------------------------------------

create index if not exists idx_verification_logs_request
on public.verification_logs(verification_request_id);

create index if not exists idx_verification_logs_performed_by
on public.verification_logs(performed_by);

create index if not exists idx_verification_logs_created_at
on public.verification_logs(created_at);

---------------------------------------------------------------
-- Row Level Security
---------------------------------------------------------------

alter table public.verification_logs
enable row level security;

---------------------------------------------------------------
-- Policies
---------------------------------------------------------------

create policy verification_logs_select_own

on public.verification_logs

for select

using (

    exists (
        select 1
        from public.verification_requests vr
        where vr.id = verification_request_id
        and vr.requested_by = auth.uid()
    )

);

create policy verification_logs_insert_authenticated

on public.verification_logs

for insert

with check (

    auth.uid() is not null

);