-- ============================================================
-- Migration : create_approval_histories
-- Module    : Governance
-- Table     : approval_histories
-- Description:
-- Immutable audit log for approval workflow events.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.approval_histories (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    approval_request_id UUID NOT NULL,

    approval_step_id UUID,

    actor_profile_id UUID,

    event VARCHAR(50) NOT NULL,

    previous_status VARCHAR(30),

    current_status VARCHAR(30),

    comment TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_approval_histories_request
        FOREIGN KEY (approval_request_id)
        REFERENCES public.approval_requests(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_approval_histories_step
        FOREIGN KEY (approval_step_id)
        REFERENCES public.approval_steps(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_approval_histories_actor
        FOREIGN KEY (actor_profile_id)
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    CONSTRAINT chk_approval_histories_event
        CHECK (
            event IN (
                'request_created',
                'step_assigned',
                'approved',
                'rejected',
                'cancelled',
                'expired',
                'reopened',
                'completed'
            )
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_approval_histories_request
ON public.approval_histories(approval_request_id);

CREATE INDEX idx_approval_histories_step
ON public.approval_histories(approval_step_id);

CREATE INDEX idx_approval_histories_actor
ON public.approval_histories(actor_profile_id);

CREATE INDEX idx_approval_histories_event
ON public.approval_histories(event);

CREATE INDEX idx_approval_histories_created_at
ON public.approval_histories(created_at);

CREATE INDEX idx_approval_histories_request_created
ON public.approval_histories(
    approval_request_id,
    created_at
);

CREATE INDEX idx_approval_histories_metadata
ON public.approval_histories
USING GIN(metadata);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.approval_histories IS
'Immutable audit log for approval workflow events.';

COMMENT ON COLUMN public.approval_histories.approval_request_id IS
'Approval request associated with this event.';

COMMENT ON COLUMN public.approval_histories.approval_step_id IS
'Approval step associated with this event, if applicable.';

COMMENT ON COLUMN public.approval_histories.actor_profile_id IS
'Profile that performed the event.';

COMMENT ON COLUMN public.approval_histories.event IS
'Workflow event type.';

COMMENT ON COLUMN public.approval_histories.previous_status IS
'Status before the event.';

COMMENT ON COLUMN public.approval_histories.current_status IS
'Status after the event.';

COMMENT ON COLUMN public.approval_histories.comment IS
'Optional comment describing the event.';

COMMENT ON COLUMN public.approval_histories.metadata IS
'Additional event metadata stored as JSONB.';

COMMENT ON COLUMN public.approval_histories.created_at IS
'Timestamp when the event occurred.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.approval_histories
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the Governance RBAC
-- infrastructure is fully implemented.