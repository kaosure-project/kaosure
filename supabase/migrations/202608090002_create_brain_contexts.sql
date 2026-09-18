-- ============================================================
-- Kao Brain
-- Table: brain_contexts
-- Purpose: Current snapshot of a Brain project
-- ============================================================

CREATE TABLE public.brain_contexts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    current_phase TEXT,
    current_focus TEXT,
    current_objective TEXT,
    current_progress TEXT,
    current_blockers TEXT,
    current_priority TEXT,
    next_step TEXT,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_brain_contexts_project
        UNIQUE (project_id)
);

CREATE INDEX idx_brain_contexts_project
ON public.brain_contexts(project_id);

CREATE INDEX idx_brain_contexts_updated
ON public.brain_contexts(updated_at DESC);

COMMENT ON TABLE public.brain_contexts IS
'Current snapshot of a Kao Brain project. This is not a historical log.';

COMMENT ON COLUMN public.brain_contexts.project_id IS
'Brain project represented by this current context snapshot.';

COMMENT ON COLUMN public.brain_contexts.current_phase IS
'Current development or project phase.';

COMMENT ON COLUMN public.brain_contexts.current_focus IS
'Current focus of the project.';

COMMENT ON COLUMN public.brain_contexts.current_objective IS
'Current objective of the project.';

COMMENT ON COLUMN public.brain_contexts.current_progress IS
'Current progress description.';

COMMENT ON COLUMN public.brain_contexts.current_blockers IS
'Current blockers preventing progress.';

COMMENT ON COLUMN public.brain_contexts.current_priority IS
'Current project priority.';

COMMENT ON COLUMN public.brain_contexts.next_step IS
'Next recommended or planned step.';

COMMENT ON COLUMN public.brain_contexts.updated_at IS
'Timestamp of the latest current-context update.';

COMMENT ON COLUMN public.brain_contexts.created_at IS
'Timestamp when the context record was created.';