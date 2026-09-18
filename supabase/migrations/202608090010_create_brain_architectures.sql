-- ============================================================
-- Kao Brain
-- Table: brain_architectures
-- Purpose: System architecture records for a Brain project
-- ============================================================

CREATE TABLE public.brain_architectures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    description TEXT,

    principle TEXT,

    components JSONB NOT NULL DEFAULT '[]'::jsonb,

    dependencies JSONB NOT NULL DEFAULT '[]'::jsonb,

    related_decisions JSONB NOT NULL DEFAULT '[]'::jsonb,

    status TEXT NOT NULL DEFAULT 'Proposed',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_brain_architectures_project
ON public.brain_architectures(project_id);

CREATE INDEX idx_brain_architectures_status
ON public.brain_architectures(status);

CREATE INDEX idx_brain_architectures_created
ON public.brain_architectures(created_at DESC);

COMMENT ON TABLE public.brain_architectures IS
'Architecture records describing the principles and structure of a Brain project.';

COMMENT ON COLUMN public.brain_architectures.principle IS
'Architectural principle governing the design.';

COMMENT ON COLUMN public.brain_architectures.components IS
'Structured list of architectural components.';

COMMENT ON COLUMN public.brain_architectures.dependencies IS
'Structured list of architecture dependencies.';

COMMENT ON COLUMN public.brain_architectures.related_decisions IS
'Structured references to related decisions.';

COMMENT ON COLUMN public.brain_architectures.status IS
'Lifecycle or governance state of the architecture record.';
