-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Expand Kao ID Identity Entity V1
-- Purpose   : Allow Personal and Business Kao IDs
-- ============================================================

---------------------------------------------------------------
-- 1. Expand identity ownership
--
-- Existing table currently supports Personal Kao ID through
-- profile_id. No existing rows are present, so profile_id can
-- safely become nullable before adding Business ownership.
---------------------------------------------------------------

ALTER TABLE public.kao_id_identities
ALTER COLUMN profile_id DROP NOT NULL;

ALTER TABLE public.kao_id_identities
ADD COLUMN IF NOT EXISTS organization_id uuid
    REFERENCES public.organizations(id)
    ON DELETE RESTRICT;

ALTER TABLE public.kao_id_identities
ADD COLUMN IF NOT EXISTS identity_type text NOT NULL
    DEFAULT 'personal';

---------------------------------------------------------------
-- 2. Identity type integrity
---------------------------------------------------------------

ALTER TABLE public.kao_id_identities
DROP CONSTRAINT IF EXISTS chk_kao_id_identity_type;

ALTER TABLE public.kao_id_identities
ADD CONSTRAINT chk_kao_id_identity_type
CHECK (
    identity_type IN (
        'personal',
        'business'
    )
);

---------------------------------------------------------------
-- 3. Exactly one owner per identity
--
-- Personal  -> profile_id required, organization_id NULL
-- Business  -> organization_id required, profile_id NULL
---------------------------------------------------------------

ALTER TABLE public.kao_id_identities
DROP CONSTRAINT IF EXISTS chk_kao_id_identity_owner;

ALTER TABLE public.kao_id_identities
ADD CONSTRAINT chk_kao_id_identity_owner
CHECK (
    (
        identity_type = 'personal'
        AND profile_id IS NOT NULL
        AND organization_id IS NULL
    )
    OR
    (
        identity_type = 'business'
        AND profile_id IS NULL
        AND organization_id IS NOT NULL
    )
);

---------------------------------------------------------------
-- 4. One Personal Kao ID per profile
---------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS uq_kao_id_identity_personal_profile
ON public.kao_id_identities(profile_id)
WHERE identity_type = 'personal';

---------------------------------------------------------------
-- 5. One Business Kao ID per organization
---------------------------------------------------------------

CREATE UNIQUE INDEX IF NOT EXISTS uq_kao_id_identity_business_organization
ON public.kao_id_identities(organization_id)
WHERE identity_type = 'business';

---------------------------------------------------------------
-- 6. Explicit entity lookup indexes
---------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_kao_id_identity_organization
ON public.kao_id_identities(organization_id);

CREATE INDEX IF NOT EXISTS idx_kao_id_identity_type
ON public.kao_id_identities(identity_type);

---------------------------------------------------------------
-- 7. Documentation
---------------------------------------------------------------

COMMENT ON COLUMN public.kao_id_identities.identity_type
IS
'Kao ID identity type: personal or business.';

COMMENT ON COLUMN public.kao_id_identities.profile_id
IS
'Owner profile for a Personal Kao ID. NULL for Business Kao IDs.';

COMMENT ON COLUMN public.kao_id_identities.organization_id
IS
'Owner organization for a Business Kao ID. NULL for Personal Kao IDs.';

COMMENT ON TABLE public.kao_id_identities
IS
'Canonical public Kao ID identities. A Kao ID belongs to exactly one verified identity owner: either a person profile or an organization.';
;
