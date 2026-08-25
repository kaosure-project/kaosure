-- ============================================================
-- Kao Brain
-- Table: brain_events
-- Purpose: Immutable historical events of a Brain project
-- ============================================================

CREATE TABLE public.brain_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    event_type TEXT NOT NULL,

    actor UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    target_type TEXT,

    target_id UUID,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_brain_events_project
ON public.brain_events(project_id);

CREATE INDEX idx_brain_events_type
ON public.brain_events(event_type);

CREATE INDEX idx_brain_events_actor
ON public.brain_events(actor);

CREATE INDEX idx_brain_events_target
ON public.brain_events(target_type, target_id);

CREATE INDEX idx_brain_events_created
ON public.brain_events(created_at DESC);

COMMENT ON TABLE public.brain_events IS
'Historical record of important events in a Kao Brain project. Events should not be modified after creation.';

COMMENT ON COLUMN public.brain_events.event_type IS
'Type of project event, such as Decision Approved, Task Created, Task Completed, Architecture Changed, or Knowledge Updated.';

COMMENT ON COLUMN public.brain_events.actor IS
'Profile responsible for the event, when applicable.';

COMMENT ON COLUMN public.brain_events.target_type IS
'Entity type affected by the event.';

COMMENT ON COLUMN public.brain_events.target_id IS
'Entity identifier affected by the event.';

COMMENT ON COLUMN public.brain_events.created_at IS
'Timestamp when the historical event occurred.';