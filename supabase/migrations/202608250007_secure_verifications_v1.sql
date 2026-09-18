-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Secure Verifications V1
-- Purpose   : Secure canonical KYC verification state
-- ============================================================

---------------------------------------------------------------
-- 1. Ensure Row Level Security is enabled
---------------------------------------------------------------

ALTER TABLE public.verifications
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- 2. Owner read policy
--
-- Users may read their own consolidated verification state.
--
-- No INSERT / UPDATE / DELETE policies are intentionally
-- provided. Client-side mutation must go through trusted
-- server-side functions.
---------------------------------------------------------------

DROP POLICY IF EXISTS verifications_select_own
ON public.verifications;

CREATE POLICY verifications_select_own

ON public.verifications

FOR SELECT

TO authenticated

USING (
    profile_id = auth.uid()
);

---------------------------------------------------------------
-- 3. Explicitly remove client mutation policies
--
-- These DROP statements are defensive. They ensure that
-- previously-created policies with these names cannot remain
-- active.
---------------------------------------------------------------

DROP POLICY IF EXISTS verifications_insert_own
ON public.verifications;

DROP POLICY IF EXISTS verifications_update_own
ON public.verifications;

DROP POLICY IF EXISTS verifications_delete_own
ON public.verifications;

---------------------------------------------------------------
-- 4. Documentation
---------------------------------------------------------------

COMMENT ON TABLE public.verifications
IS
'Canonical consolidated KYC verification state for each Kao ID profile. Client applications may read their own state, while mutations are performed through trusted server-side functions.';

COMMENT ON COLUMN public.verifications.profile_id
IS
'Profile that owns this canonical verification state. One verification record per profile.';

COMMENT ON COLUMN public.verifications.status
IS
'Canonical KYC status: not_started, pending, approved, rejected, or expired.';

COMMENT ON COLUMN public.verifications.account_level
IS
'Account level derived from the verified identity state.';

---------------------------------------------------------------
-- 5. Verification integrity
--
-- One canonical verification record per profile.
---------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS idx_verifications_profile
ON public.verifications(profile_id);