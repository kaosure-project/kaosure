-- ============================================================
-- Migration : create_approval_policies
-- Module    : Governance
-- Table     : approval_policies
-- Description:
-- Defines approval rules for protected business actions.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.approval_policies (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code VARCHAR(150) NOT NULL,

    name VARCHAR(150) NOT NULL,

    description TEXT,

    resource VARCHAR(100) NOT NULL,

    action VARCHAR(100) NOT NULL,

    minimum_approvals INTEGER NOT NULL DEFAULT 1,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    is_immutable BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_approval_policies_code
        UNIQUE (code),

    CONSTRAINT chk_approval_policies_minimum_approvals
        CHECK (minimum_approvals >= 1)

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_approval_policies_resource
ON public.approval_policies(resource);

CREATE INDEX idx_approval_policies_action
ON public.approval_policies(action);

CREATE INDEX idx_approval_policies_resource_action
ON public.approval_policies(resource, action);

CREATE INDEX idx_approval_policies_is_active
ON public.approval_policies(is_active);

CREATE INDEX idx_approval_policies_is_immutable
ON public.approval_policies(is_immutable);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.approval_policies IS
'Defines approval policies for protected business operations.';

COMMENT ON COLUMN public.approval_policies.code IS
'Globally unique approval policy code.';

COMMENT ON COLUMN public.approval_policies.name IS
'Human-readable approval policy name.';

COMMENT ON COLUMN public.approval_policies.description IS
'Detailed description of the approval policy.';

COMMENT ON COLUMN public.approval_policies.resource IS
'Protected business resource.';

COMMENT ON COLUMN public.approval_policies.action IS
'Protected business action.';

COMMENT ON COLUMN public.approval_policies.minimum_approvals IS
'Minimum number of approvals required before completion.';

COMMENT ON COLUMN public.approval_policies.is_active IS
'Whether the approval policy is active.';

COMMENT ON COLUMN public.approval_policies.is_immutable IS
'Indicates a built-in system policy that cannot be modified or deleted.';

COMMENT ON COLUMN public.approval_policies.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.approval_policies.updated_at IS
'Record last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.approval_policies
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be added after Governance RBAC is completed.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_approval_policies_updated_at
BEFORE UPDATE
ON public.approval_policies
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();