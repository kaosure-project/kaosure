-- ============================================================
-- Kao ID
-- Table: document_files
-- Description:
-- เก็บไฟล์รูปภาพหรือเอกสารของ Identity Document
-- ============================================================

create table if not exists public.document_files (

    id uuid primary key default gen_random_uuid(),

    document_id uuid not null
        references public.identity_documents(id)
        on delete cascade,

    file_path text not null,

    file_name text not null,

    mime_type text not null,

    file_size bigint not null,

    uploaded_at timestamptz not null default now(),

    created_at timestamptz not null default now(),

    updated_at timestamptz not null default now()

);

comment on table public.document_files
is 'Files belonging to an identity document';

comment on column public.document_files.document_id
is 'Reference to identity document';

comment on column public.document_files.file_path
is 'Supabase Storage path';

comment on column public.document_files.file_name
is 'Original filename';

comment on column public.document_files.mime_type
is 'File MIME type';

comment on column public.document_files.file_size
is 'File size in bytes';

---------------------------------------------------------------
-- Indexes
---------------------------------------------------------------

create index if not exists idx_document_files_document
on public.document_files(document_id);

---------------------------------------------------------------
-- Trigger
---------------------------------------------------------------

drop trigger if exists trg_document_files_updated_at
on public.document_files;

create trigger trg_document_files_updated_at

before update

on public.document_files

for each row

execute function public.update_updated_at_column();

---------------------------------------------------------------
-- Row Level Security
---------------------------------------------------------------

alter table public.document_files
enable row level security;

---------------------------------------------------------------
-- Policies
---------------------------------------------------------------

create policy document_files_select_own

on public.document_files

for select

using (

    exists (
        select 1
        from public.identity_documents d
        where d.id = document_id
        and d.owner_id = auth.uid()
    )

);

create policy document_files_insert_own

on public.document_files

for insert

with check (

    exists (
        select 1
        from public.identity_documents d
        where d.id = document_id
        and d.owner_id = auth.uid()
    )

);

create policy document_files_update_own

on public.document_files

for update

using (

    exists (
        select 1
        from public.identity_documents d
        where d.id = document_id
        and d.owner_id = auth.uid()
    )

);

create policy document_files_delete_own

on public.document_files

for delete

using (

    exists (
        select 1
        from public.identity_documents d
        where d.id = document_id
        and d.owner_id = auth.uid()
    )

);