-- ============================================================
-- Kao Ecosystem / Kao ID
-- Migration : Organization Identity V1
-- Purpose   : Legal organization identity + business membership
-- ============================================================

---------------------------------------------------------------
-- 1. Canonical legal identity of an organization
---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.organization_legal_profiles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL
        REFERENCES public.organizations(id) ON DELETE CASCADE,
    registration_number text NOT NULL,
    legal_name text NOT NULL,
    organization_type text NOT NULL DEFAULT 'company',
    registration_country text NOT NULL DEFAULT 'TH',
    registration_status text NOT NULL DEFAULT 'active',
    verification_status text NOT NULL DEFAULT 'pending',
    verified_at timestamptz,
    verified_by uuid REFERENCES public.profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT uq_organization_legal_profile_organization
        UNIQUE (organization_id),
    CONSTRAINT uq_organization_legal_profile_registration
        UNIQUE (registration_country, registration_number),
    CONSTRAINT chk_organization_legal_profile_registration_status
        CHECK (registration_status IN ('active','inactive')),
    CONSTRAINT chk_organization_legal_profile_verification_status
        CHECK (verification_status IN ('pending','approved','rejected'))
);

COMMENT ON TABLE public.organization_legal_profiles IS
'Canonical legal identity information for organizations used by Kao ID Business Identity.';

COMMENT ON COLUMN public.organization_legal_profiles.registration_number IS
'Official legal registration number of the organization.';

COMMENT ON COLUMN public.organization_legal_profiles.legal_name IS
'Official legal name of the organization.';

COMMENT ON COLUMN public.organization_legal_profiles.verification_status IS
'Business identity verification state: pending, approved, or rejected.';

---------------------------------------------------------------
-- 2. Extend the EXISTING organization_members model
--
-- organization_members already existed in the KaoSure schema.
-- We extend its role vocabulary instead of creating a duplicate
-- membership table.
---------------------------------------------------------------

ALTER TABLE public.organization_members
DROP CONSTRAINT IF EXISTS organization_members_role_check;

ALTER TABLE public.organization_members
ADD CONSTRAINT organization_members_role_check
CHECK (
    role IN (
        'owner',
        'director',
        'authorized_person',
        'admin',
        'finance',
        'staff',
        'member'
    )
);

COMMENT ON TABLE public.organization_members IS
'Canonical relationship between a profile and an organization. Supports business identity roles including owner, director, and authorized_person.';

COMMENT ON COLUMN public.organization_members.role IS
'Organization-specific role: owner, director, authorized_person, admin, finance, staff, or member.';

---------------------------------------------------------------
-- 3. Indexes
---------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_organization_legal_profiles_status
ON public.organization_legal_profiles(verification_status);

CREATE INDEX IF NOT EXISTS idx_organization_legal_profiles_registration_status
ON public.organization_legal_profiles(registration_status);

CREATE INDEX IF NOT EXISTS idx_organization_members_organization
ON public.organization_members(organization_id);

CREATE INDEX IF NOT EXISTS idx_organization_members_profile
ON public.organization_members(profile_id);

CREATE INDEX IF NOT EXISTS idx_organization_members_role
ON public.organization_members(role);

CREATE INDEX IF NOT EXISTS idx_organization_members_status
ON public.organization_members(status);

---------------------------------------------------------------
-- 4. Updated-at trigger for legal profile
---------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_organization_legal_profiles_updated_at
ON public.organization_legal_profiles;

CREATE TRIGGER trg_organization_legal_profiles_updated_at
BEFORE UPDATE
ON public.organization_legal_profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

---------------------------------------------------------------
-- 5. Row Level Security
---------------------------------------------------------------

ALTER TABLE public.organization_legal_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- 6. Read policies
---------------------------------------------------------------

DROP POLICY IF EXISTS organization_legal_profiles_select_member
ON public.organization_legal_profiles;

CREATE POLICY organization_legal_profiles_select_member
ON public.organization_legal_profiles
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = organization_legal_profiles.organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
    )
);

DROP POLICY IF EXISTS organization_members_select_own
ON public.organization_members;

CREATE POLICY organization_members_select_own
ON public.organization_members
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
    OR EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = organization_members.organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
          AND om.role IN ('owner','director','authorized_person','admin')
    )
);

---------------------------------------------------------------
-- 7. No direct client mutation
---------------------------------------------------------------

DROP POLICY IF EXISTS organization_legal_profiles_insert_own
ON public.organization_legal_profiles;
DROP POLICY IF EXISTS organization_legal_profiles_update_own
ON public.organization_legal_profiles;
DROP POLICY IF EXISTS organization_legal_profiles_delete_own
ON public.organization_legal_profiles;

DROP POLICY IF EXISTS organization_members_insert_own
ON public.organization_members;
DROP POLICY IF EXISTS organization_members_update_own
ON public.organization_members;
DROP POLICY IF EXISTS organization_members_delete_own
ON public.organization_members;

COMMENT ON TABLE public.organization_legal_profiles IS
'Canonical legal identity information for organizations used by Kao ID Business Identity. Client mutation is controlled by trusted server-side workflows.';

COMMENT ON TABLE public.organization_members IS
'Canonical relationship between profiles and organizations. Membership mutation is controlled by trusted server-side workflows.';
;
