-- ============================================================
-- Migration : create_admin_assignments
-- Module    : Governance
-- Table     : admin_assignments
-- Description:
-- Assigns administrator roles to user profiles.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.admin_assignments (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id UUID NOT NULL,

    role_id UUID NOT NULL,

    assigned_by UUID NOT NULL,

    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    expires_at TIMESTAMPTZ,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_admin_assignments_profile
        FOREIGN KEY (profile_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_admin_assignments_role
        FOREIGN KEY (role_id)
        REFERENCES public.admin_roles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_admin_assignments_assigned_by
        FOREIGN KEY (assigned_by)
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_admin_assignment
        UNIQUE (
            profile_id,
            role_id
        ),

    CONSTRAINT chk_admin_assignment_dates
        CHECK (
            expires_at IS NULL
            OR
            expires_at > starts_at
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_admin_assignments_profile
ON public.admin_assignments(profile_id);

CREATE INDEX idx_admin_assignments_role
ON public.admin_assignments(role_id);

CREATE INDEX idx_admin_assignments_assigned_by
ON public.admin_assignments(assigned_by);

CREATE INDEX idx_admin_assignments_is_active
ON public.admin_assignments(is_active);

CREATE INDEX idx_admin_assignments_expires_at
ON public.admin_assignments(expires_at);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.admin_assignments IS
'Assigns administrator roles to user profiles.';

COMMENT ON COLUMN public.admin_assignments.profile_id IS
'Profile receiving the administrator role.';

COMMENT ON COLUMN public.admin_assignments.role_id IS
'Assigned administrator role.';

COMMENT ON COLUMN public.admin_assignments.assigned_by IS
'Profile that granted the administrator role.';

COMMENT ON COLUMN public.admin_assignments.starts_at IS
'Timestamp when the role becomes effective.';

COMMENT ON COLUMN public.admin_assignments.expires_at IS
'Timestamp when the role assignment expires.';

COMMENT ON COLUMN public.admin_assignments.is_active IS
'Indicates whether the role assignment is currently active.';

COMMENT ON COLUMN public.admin_assignments.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.admin_assignments.updated_at IS
'Record last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.admin_assignments
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the RBAC infrastructure
-- is fully implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_admin_assignments_updated_at
BEFORE UPDATE
ON public.admin_assignments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();