-- ============================================================
-- Kao Brain
-- Table: brain_ideas
-- Purpose: Ideas that have not necessarily become decisions
-- ============================================================

CREATE TABLE public.brain_ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    description TEXT,

    source TEXT,

    status TEXT NOT NULL DEFAULT 'New',

    related_tasks JSONB NOT NULL DEFAULT '[]'::jsonb,

    related_decisions JSONB NOT NULL DEFAULT '[]'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_ideas_status_check
        CHECK (
            status IN (
                'New',
                'Evaluating',
                'Accepted',
                'Rejected',
                'Converted'
            )
        )
);

CREATE INDEX idx_brain_ideas_project
ON public.brain_ideas(project_id);

CREATE INDEX idx_brain_ideas_status
ON public.brain_ideas(status);

CREATE INDEX idx_brain_ideas_created
ON public.brain_ideas(created_at DESC);

COMMENT ON TABLE public.brain_ideas IS
'Ideas that may or may not become decisions or tasks.';

COMMENT ON COLUMN public.brain_ideas.related_tasks IS
'Structured references to related tasks.';

COMMENT ON COLUMN public.brain_ideas.related_decisions IS
'Structured references to related decisions.';

COMMENT ON COLUMN public.brain_ideas.status IS
'New, Evaluating, Accepted, Rejected, or Converted.';