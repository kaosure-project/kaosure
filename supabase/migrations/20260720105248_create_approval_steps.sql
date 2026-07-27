-- ============================================================
-- Migration : create_approval_steps
-- Module    : Governance
-- Table     : approval_steps
-- Description:
-- Stores approval workflow steps for each approval request.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.approval_steps (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    approval_request_id UUID NOT NULL,

    role_id UUID NOT NULL,

    step_order INTEGER NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'pending',

    approved_by UUID,

    approved_at TIMESTAMPTZ,

    comment TEXT,

    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_approval_steps_request
        FOREIGN KEY (approval_request_id)
        REFERENCES public.approval_requests(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_approval_steps_role
        FOREIGN KEY (role_id)
        REFERENCES public.admin_roles(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_approval_steps_approved_by
        FOREIGN KEY (approved_by)
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    CONSTRAINT uq_approval_steps_request_order
        UNIQUE (
            approval_request_id,
            step_order
        ),

    CONSTRAINT chk_approval_steps_order
        CHECK (step_order >= 1),

    CONSTRAINT chk_approval_steps_status
        CHECK (
            status IN (
                'pending',
                'approved',
                'rejected',
                'skipped',
                'expired'
            )
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_approval_steps_request
ON public.approval_steps(approval_request_id);

CREATE INDEX idx_approval_steps_role
ON public.approval_steps(role_id);

CREATE INDEX idx_approval_steps_status
ON public.approval_steps(status);

CREATE INDEX idx_approval_steps_order
ON public.approval_steps(step_order);

CREATE INDEX idx_approval_steps_approved_by
ON public.approval_steps(approved_by);

CREATE INDEX idx_approval_steps_expires_at
ON public.approval_steps(expires_at);

CREATE INDEX idx_approval_steps_request_status
ON public.approval_steps(
    approval_request_id,
    status
);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.approval_steps IS
'Stores workflow approval steps for each approval request.';

COMMENT ON COLUMN public.approval_steps.approval_request_id IS
'Reference to the approval request.';

COMMENT ON COLUMN public.approval_steps.role_id IS
'Administrator role responsible for this approval step.';

COMMENT ON COLUMN public.approval_steps.step_order IS
'Execution order within the approval workflow.';

COMMENT ON COLUMN public.approval_steps.status IS
'Current status of the approval step.';

COMMENT ON COLUMN public.approval_steps.approved_by IS
'Profile that completed this approval step.';

COMMENT ON COLUMN public.approval_steps.approved_at IS
'Timestamp when the approval step was completed.';

COMMENT ON COLUMN public.approval_steps.comment IS
'Optional comment from the approver.';

COMMENT ON COLUMN public.approval_steps.expires_at IS
'Expiration timestamp for this approval step.';

COMMENT ON COLUMN public.approval_steps.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.approval_steps.updated_at IS
'Last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.approval_steps
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the Governance RBAC
-- infrastructure is fully implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_approval_steps_updated_at
BEFORE UPDATE
ON public.approval_steps
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();