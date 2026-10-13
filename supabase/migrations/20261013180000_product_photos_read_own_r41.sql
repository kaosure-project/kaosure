-- R41: members can see the product photos in their own folder.
-- Storage remove() only deletes rows the caller can also select, so without this policy the app's photo
-- cleanup (removed_paths, deleted drafts) removed nothing. Photos kept as order evidence stay protected by
-- the R40 delete policy.

drop policy if exists "Secondhand product photos read own folder" on storage.objects;
create policy "Secondhand product photos read own folder" on storage.objects
  for select to authenticated
  using (bucket_id = 'marketplace-product-images'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
