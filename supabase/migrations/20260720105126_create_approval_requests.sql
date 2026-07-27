-- ============================================================
-- Migration : create_approval_requests
-- Module    : Governance
-- Table     : approval_requests
-- Description:
-- Stores approval request transactions.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.approval_requests (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    policy_id UUID NOT NULL,

    requested_by UUID NOT NULL,

    resource VARCHAR(100) NOT NULL,

    resource_id UUID NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'pending',

    reason TEXT,

    expires_at TIMESTAMPTZ,

    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_approval_requests_policy
        FOREIGN KEY (policy_id)
        REFERENCES public.approval_policies(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_approval_requests_requested_by
        FOREIGN KEY (requested_by)
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_approval_requests_status
        CHECK (
            status IN (
                'pending',
                'approved',
                'rejected',
                'cancelled',
                'expired'
            )
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_approval_requests_policy
ON public.approval_requests(policy_id);

CREATE INDEX idx_approval_requests_requested_by
ON public.approval_requests(requested_by);

CREATE INDEX idx_approval_requests_resource
ON public.approval_requests(resource);

CREATE INDEX idx_approval_requests_resource_id
ON public.approval_requests(resource_id);

CREATE INDEX idx_approval_requests_status
ON public.approval_requests(status);

CREATE INDEX idx_approval_requests_created_at
ON public.approval_requests(created_at);

CREATE INDEX idx_approval_requests_expires_at
ON public.approval_requests(expires_at);

CREATE INDEX idx_approval_requests_resource_lookup
ON public.approval_requests(resource, resource_id);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.approval_requests IS
'Stores approval request transactions.';

COMMENT ON COLUMN public.approval_requests.policy_id IS
'Approval policy applied to this request.';

COMMENT ON COLUMN public.approval_requests.requested_by IS
'Profile that created the approval request.';

COMMENT ON COLUMN public.approval_requests.resource IS
'Business resource requiring approval.';

COMMENT ON COLUMN public.approval_requests.resource_id IS
'Primary record requiring approval.';

COMMENT ON COLUMN public.approval_requests.status IS
'Current approval status.';

COMMENT ON COLUMN public.approval_requests.reason IS
'Reason provided by the requester.';

COMMENT ON COLUMN public.approval_requests.expires_at IS
'Expiration time of the approval request.';

COMMENT ON COLUMN public.approval_requests.completed_at IS
'Time when the request reached a final state.';

COMMENT ON COLUMN public.approval_requests.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.approval_requests.updated_at IS
'Record last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.approval_requests
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the Governance RBAC
-- infrastructure is fully implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_approval_requests_updated_at
BEFORE UPDATE
ON public.approval_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();