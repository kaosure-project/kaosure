CREATE TABLE public.brain_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,

    slug TEXT NOT NULL UNIQUE,

    description TEXT,

    status TEXT NOT NULL DEFAULT 'active',

    owner_profile_id UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_projects_status_check
        CHECK (
            status IN (
                'active',
                'paused',
                'completed',
                'archived'
            )
        )
);

CREATE INDEX idx_brain_projects_owner
    ON public.brain_projects(owner_profile_id);

CREATE INDEX idx_brain_projects_status
    ON public.brain_projects(status);