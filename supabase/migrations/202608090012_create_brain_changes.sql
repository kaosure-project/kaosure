-- ============================================================
-- Kao Brain
-- Table: brain_changes
-- Purpose: Important changes to governed Brain entities
-- ============================================================

CREATE TABLE public.brain_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    target_type TEXT NOT NULL,

    target_id UUID NOT NULL,

    previous_state JSONB,

    proposed_state JSONB,

    reason TEXT,

    impact TEXT,

    approved_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    executed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_brain_changes_project
ON public.brain_changes(project_id);

CREATE INDEX idx_brain_changes_target
ON public.brain_changes(target_type, target_id);

CREATE INDEX idx_brain_changes_approved_by
ON public.brain_changes(approved_by);

CREATE INDEX idx_brain_changes_created
ON public.brain_changes(created_at DESC);

CREATE INDEX idx_brain_changes_executed
ON public.brain_changes(executed_at);

COMMENT ON TABLE public.brain_changes IS
'Records important proposed and executed changes to governed Brain entities.';

COMMENT ON COLUMN public.brain_changes.target_type IS
'Type of entity being changed.';

COMMENT ON COLUMN public.brain_changes.target_id IS
'Identifier of the entity being changed.';

COMMENT ON COLUMN public.brain_changes.previous_state IS
'State of the target before the proposed change.';

COMMENT ON COLUMN public.brain_changes.proposed_state IS
'State proposed after the change.';

COMMENT ON COLUMN public.brain_changes.approved_by IS
'Profile that approved the change, when approval is required.';

COMMENT ON COLUMN public.brain_changes.executed_at IS
'Timestamp when the approved change was actually executed.';