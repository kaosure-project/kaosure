-- R44: security hardening from the read-only database audit of 2026-10-14.
-- The RPC allowlist (oauth_client_guard_r18) only applies to app tokens that carry a client_id; guests and
-- first-party Kao ID sessions are limited by grants alone, so every grant below is the real boundary.

-- ---------------------------------------------------------------------------
-- Financial verification checks are internal: they answer for any profile id, so members must not call them.
-- Every caller is a SECURITY DEFINER function owned by postgres and keeps working.
-- ---------------------------------------------------------------------------
revoke execute on function public.is_identity_financially_verified(text, uuid, uuid) from public, anon, authenticated;
revoke execute on function public.is_seller_financially_verified(uuid) from public, anon, authenticated;

alter function public.is_identity_financially_verified(text, uuid, uuid) set search_path = '';
alter function public.is_seller_financially_verified(uuid) set search_path = '';
alter function public.initialize_verification(uuid) set search_path = '';

-- ---------------------------------------------------------------------------
-- Kao ID avatars: public bucket, so only small images.
-- ---------------------------------------------------------------------------
update storage.buckets
   set file_size_limit = 2097152,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
 where id = 'avatars';

-- ---------------------------------------------------------------------------
-- Market profiles are public, but only the face of the member: not when it was seeded from Kao ID.
-- ---------------------------------------------------------------------------
revoke select on secondhand.member_profiles from anon, authenticated;
grant select (profile_id, display_name, avatar_url, bio, created_at, updated_at)
  on secondhand.member_profiles to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Top-up settings are read and written only through definer functions; RLS without policies backs that up.
-- ---------------------------------------------------------------------------
alter table kaoid_private.topup_settings_r28 enable row level security;
