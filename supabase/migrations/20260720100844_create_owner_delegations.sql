-- ============================================================
-- Migration: create_owner_delegations
-- Module    : Governance
-- Table     : owner_delegations
-- Description:
-- Stores temporary authority delegations from the Company Owner
-- to another verified KaoSure member.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.owner_delegations (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    owner_profile_id UUID NOT NULL,

    delegate_profile_id UUID NOT NULL,

    reason TEXT,

    starts_at TIMESTAMPTZ NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL,

    revoked_at TIMESTAMPTZ,

    revoked_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_owner_delegations_owner
        FOREIGN KEY (owner_profile_id)
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_owner_delegations_delegate
        FOREIGN KEY (delegate_profile_id)
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_owner_delegations_revoked_by
        FOREIGN KEY (revoked_by)
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_owner_delegations_dates
        CHECK (expires_at > starts_at),

    CONSTRAINT chk_owner_delegations_not_self
        CHECK (owner_profile_id <> delegate_profile_id)

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_owner_delegations_owner
ON public.owner_delegations(owner_profile_id);

CREATE INDEX idx_owner_delegations_delegate
ON public.owner_delegations(delegate_profile_id);

CREATE INDEX idx_owner_delegations_expires_at
ON public.owner_delegations(expires_at);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.owner_delegations IS
'Stores temporary authority delegations from the Company Owner.';

COMMENT ON COLUMN public.owner_delegations.owner_profile_id IS
'Company Owner profile.';

COMMENT ON COLUMN public.owner_delegations.delegate_profile_id IS
'Profile receiving delegated authority.';

COMMENT ON COLUMN public.owner_delegations.reason IS
'Reason for delegation.';

COMMENT ON COLUMN public.owner_delegations.starts_at IS
'Delegation start time.';

COMMENT ON COLUMN public.owner_delegations.expires_at IS
'Delegation expiration time.';

COMMENT ON COLUMN public.owner_delegations.revoked_at IS
'Time when delegation was revoked.';

COMMENT ON COLUMN public.owner_delegations.revoked_by IS
'Profile that revoked the delegation.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.owner_delegations
ENABLE ROW LEVEL SECURITY;

-- RLS Policies will be added after Governance RBAC is completed.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_owner_delegations_updated_at
BEFORE UPDATE
ON public.owner_delegations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();