-- ============================================================
-- Kao Brain
-- Table: brain_decisions
-- Purpose: Project decisions and their authority state
-- ============================================================

CREATE TABLE public.brain_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'Proposed',

    decision TEXT NOT NULL,

    reason TEXT,

    impact TEXT,

    approved_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    supersedes UUID
        REFERENCES public.brain_decisions(id)
        ON DELETE SET NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_decisions_status_check
        CHECK (
            status IN (
                'Proposed',
                'Approved',
                'Rejected',
                'Superseded'
            )
        ),

    CONSTRAINT brain_decisions_approved_check
        CHECK (
            status <> 'Approved'
            OR (
                approved_by IS NOT NULL
                AND approved_at IS NOT NULL
            )
        )
);

CREATE INDEX idx_brain_decisions_project
ON public.brain_decisions(project_id);

CREATE INDEX idx_brain_decisions_status
ON public.brain_decisions(status);

CREATE INDEX idx_brain_decisions_approved_by
ON public.brain_decisions(approved_by);

CREATE INDEX idx_brain_decisions_supersedes
ON public.brain_decisions(supersedes);

CREATE INDEX idx_brain_decisions_created
ON public.brain_decisions(created_at DESC);

COMMENT ON TABLE public.brain_decisions IS
'Stores project decisions and their authority state.';

COMMENT ON COLUMN public.brain_decisions.status IS
'Proposed, Approved, Rejected, or Superseded.';

COMMENT ON COLUMN public.brain_decisions.approved_by IS
'Profile that approved the decision.';

COMMENT ON COLUMN public.brain_decisions.approved_at IS
'Timestamp when the decision was approved.';

COMMENT ON COLUMN public.brain_decisions.supersedes IS
'Previous decision superseded by this decision.';