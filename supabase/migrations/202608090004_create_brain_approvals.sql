-- ============================================================
-- Kao Brain
-- Table: brain_approvals
-- Purpose: Approval records for governed Brain entities
-- ============================================================

CREATE TABLE public.brain_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    target_type TEXT NOT NULL,

    target_id UUID NOT NULL,

    action TEXT NOT NULL,

    decision TEXT NOT NULL,

    approved_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    comment TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_approvals_decision_check
        CHECK (
            decision IN (
                'Approved',
                'Rejected'
            )
        ),

    CONSTRAINT brain_approvals_target_type_check
        CHECK (
            target_type IN (
                'Decision',
                'BusinessRule',
                'Architecture',
                'SecurityChange',
                'ProductionChange',
                'DatabaseChange',
                'DataDeletion',
                'Task'
            )
        ),

    CONSTRAINT brain_approvals_approved_check
        CHECK (
            decision <> 'Approved'
            OR (
                approved_by IS NOT NULL
                AND approved_at IS NOT NULL
            )
        )
);

CREATE INDEX idx_brain_approvals_project
ON public.brain_approvals(project_id);

CREATE INDEX idx_brain_approvals_target
ON public.brain_approvals(target_type, target_id);

CREATE INDEX idx_brain_approvals_decision
ON public.brain_approvals(decision);

CREATE INDEX idx_brain_approvals_approved_by
ON public.brain_approvals(approved_by);

CREATE INDEX idx_brain_approvals_created
ON public.brain_approvals(created_at DESC);

COMMENT ON TABLE public.brain_approvals IS
'Approval records for governed Kao Brain entities.';

COMMENT ON COLUMN public.brain_approvals.target_type IS
'Type of entity being approved.';

COMMENT ON COLUMN public.brain_approvals.target_id IS
'ID of the entity being approved.';

COMMENT ON COLUMN public.brain_approvals.action IS
'Action being requested or approved.';

COMMENT ON COLUMN public.brain_approvals.decision IS
'Approval decision: Approved or Rejected.';

COMMENT ON COLUMN public.brain_approvals.approved_by IS
'Profile that approved the target.';

COMMENT ON COLUMN public.brain_approvals.approved_at IS
'Timestamp when approval was granted.';