-- ============================================================
-- Kao ID
-- Table: identity_documents
-- Description:
-- เก็บข้อมูลเอกสารยืนยันตัวตนของผู้ใช้
-- ============================================================

create table if not exists public.identity_documents (

    id uuid primary key default gen_random_uuid(),

    owner_id uuid not null
        references public.profiles(id)
        on delete cascade,

    document_type text not null,

    document_number text not null,

    issued_date date,

    expiry_date date,

    status text not null,

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()

);

comment on table public.identity_documents
is 'Identity documents used for KYC verification';

comment on column public.identity_documents.owner_id
is 'Owner profile';

comment on column public.identity_documents.document_type
is 'Passport, National ID, Driving License';

comment on column public.identity_documents.document_number
is 'Official document number';

comment on column public.identity_documents.status
is 'Current document status';

---------------------------------------------------------------
-- Indexes
---------------------------------------------------------------

create index if not exists idx_identity_documents_owner
on public.identity_documents(owner_id);

create index if not exists idx_identity_documents_status
on public.identity_documents(status);

create index if not exists idx_identity_documents_type
on public.identity_documents(document_type);

---------------------------------------------------------------
-- Trigger
---------------------------------------------------------------

drop trigger if exists trg_identity_documents_updated_at
on public.identity_documents;

create trigger trg_identity_documents_updated_at

before update

on public.identity_documents

for each row

execute function public.update_updated_at_column();

---------------------------------------------------------------
-- Row Level Security
---------------------------------------------------------------

alter table public.identity_documents
enable row level security;

---------------------------------------------------------------
-- Policies
---------------------------------------------------------------

create policy identity_documents_select_own

on public.identity_documents

for select

using (

    auth.uid() = owner_id

);

create policy identity_documents_insert_own

on public.identity_documents

for insert

with check (

    auth.uid() = owner_id

);

create policy identity_documents_update_own

on public.identity_documents

for update

using (

    auth.uid() = owner_id

);

create policy identity_documents_delete_own

on public.identity_documents

for delete

using (

    auth.uid() = owner_id

);