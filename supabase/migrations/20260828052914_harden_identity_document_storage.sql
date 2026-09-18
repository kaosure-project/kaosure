update storage.buckets set public = false, file_size_limit = 10485760, allowed_mime_types = array['image/jpeg','image/png','application/pdf'] where id = 'identity-documents';

drop policy if exists identity_documents_delete_own on public.identity_documents;
create policy identity_documents_delete_draft_own
on public.identity_documents
for delete
to public
using (
  auth.uid() = owner_id
  and status = 'draft'
);

drop policy if exists identity_documents_update_own on public.identity_documents;
create policy identity_documents_update_draft_own
on public.identity_documents
for update
to public
using (
  auth.uid() = owner_id
  and status = 'draft'
)
with check (
  auth.uid() = owner_id
  and status = 'draft'
);

drop policy if exists identity_documents_delete_own on storage.objects;
create policy identity_documents_delete_draft_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'identity-documents'
  and owner_id = (select auth.uid()::text)
  and exists (
    select 1
    from public.identity_documents d
    where d.owner_id = auth.uid()
      and d.file_path = name
      and d.status = 'draft'
  )
);

drop policy if exists identity_documents_update_own on storage.objects;
create policy identity_documents_update_draft_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'identity-documents'
  and owner_id = (select auth.uid()::text)
  and exists (
    select 1
    from public.identity_documents d
    where d.owner_id = auth.uid()
      and d.file_path = name
      and d.status = 'draft'
  )
)
with check (
  bucket_id = 'identity-documents'
  and owner_id = (select auth.uid()::text)
  and exists (
    select 1
    from public.identity_documents d
    where d.owner_id = auth.uid()
      and d.file_path = name
      and d.status = 'draft'
  )
);;
