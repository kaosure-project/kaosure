-- ============================================================
-- Kao Brain
-- Table: brain_knowledge
-- Purpose: Reference knowledge used by AI retrieval
-- ============================================================

CREATE TABLE public.brain_knowledge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    category TEXT NOT NULL,

    content TEXT NOT NULL,

    source TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_knowledge_category_check
        CHECK (
            category IN (
                'Technical',
                'Coding',
                'Architecture',
                'Development',
                'AI',
                'Reference'
            )
        ),

    CONSTRAINT brain_knowledge_status_check
        CHECK (
            status IN (
                'active',
                'deprecated',
                'archived'
            )
        )
);

CREATE INDEX idx_brain_knowledge_project
ON public.brain_knowledge(project_id);

CREATE INDEX idx_brain_knowledge_category
ON public.brain_knowledge(category);

CREATE INDEX idx_brain_knowledge_status
ON public.brain_knowledge(status);

CREATE INDEX idx_brain_knowledge_created
ON public.brain_knowledge(created_at DESC);

COMMENT ON TABLE public.brain_knowledge IS
'Reference knowledge used by Kao Brain retrieval. Knowledge must not override approved decisions or business rules.';

COMMENT ON COLUMN public.brain_knowledge.category IS
'Knowledge category: Technical, Coding, Architecture, Development, AI, or Reference.';

COMMENT ON COLUMN public.brain_knowledge.content IS
'Reference content used by AI retrieval.';

COMMENT ON COLUMN public.brain_knowledge.source IS
'Original source of the knowledge.';

COMMENT ON COLUMN public.brain_knowledge.status IS
'Lifecycle state of the knowledge record.';