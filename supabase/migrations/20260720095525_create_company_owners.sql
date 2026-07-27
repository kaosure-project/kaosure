-- ============================================================
-- Migration: create_company_owners
-- Module    : Governance
-- Table     : company_owners
-- Description:
-- Stores the single Company Owner of KaoSure.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.company_owners (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_company_owners_profile
        FOREIGN KEY (profile_id)
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_company_owners_profile
        UNIQUE (profile_id)

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_company_owners_profile_id
ON public.company_owners(profile_id);

-- ============================================================
-- ENSURE ONLY ONE COMPANY OWNER
-- ============================================================

CREATE UNIQUE INDEX uq_company_owner_singleton
ON public.company_owners((TRUE));

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.company_owners IS
'Stores the single Company Owner of KaoSure with the highest governance authority.';

COMMENT ON COLUMN public.company_owners.id IS
'Primary key.';

COMMENT ON COLUMN public.company_owners.profile_id IS
'Reference to profiles.id of the Company Owner.';

COMMENT ON COLUMN public.company_owners.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.company_owners.updated_at IS
'Last record update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.company_owners
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be added after Governance RBAC is implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_company_owners_updated_at
BEFORE UPDATE
ON public.company_owners
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();