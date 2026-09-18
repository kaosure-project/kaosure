-- ============================================================
-- Kao Brain
-- Table: brain_visions
-- Purpose: Long-term direction of a Brain project
-- ============================================================

CREATE TABLE public.brain_visions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    description TEXT,

    goals JSONB NOT NULL DEFAULT '[]'::jsonb,

    principles JSONB NOT NULL DEFAULT '[]'::jsonb,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_visions_status_check
        CHECK (
            status IN (
                'active',
                'deprecated',
                'archived'
            )
        )
);

CREATE INDEX idx_brain_visions_project
ON public.brain_visions(project_id);

CREATE INDEX idx_brain_visions_status
ON public.brain_visions(status);

CREATE INDEX idx_brain_visions_created
ON public.brain_visions(created_at DESC);

COMMENT ON TABLE public.brain_visions IS
'Long-term direction, goals, and principles of a Kao Brain project.';

COMMENT ON COLUMN public.brain_visions.goals IS
'Structured long-term goals of the project.';

COMMENT ON COLUMN public.brain_visions.principles IS
'Structured principles guiding the project.';

COMMENT ON COLUMN public.brain_visions.status IS
'Lifecycle state of the vision.';