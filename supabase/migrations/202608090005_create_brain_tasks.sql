-- ============================================================
-- Kao Brain
-- Table: brain_tasks
-- Purpose: Work items managed by Kao Brain
-- ============================================================

CREATE TABLE public.brain_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'TODO',

    priority TEXT NOT NULL DEFAULT 'normal',

    description TEXT,

    reason TEXT,

    current_state TEXT,

    expected_result TEXT,

    dependencies JSONB NOT NULL DEFAULT '[]'::jsonb,

    blocked_reason TEXT,

    related_files JSONB NOT NULL DEFAULT '[]'::jsonb,

    related_features JSONB NOT NULL DEFAULT '[]'::jsonb,

    related_decisions JSONB NOT NULL DEFAULT '[]'::jsonb,

    completion_criteria JSONB NOT NULL DEFAULT '[]'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    completed_at TIMESTAMPTZ,

    CONSTRAINT brain_tasks_status_check
        CHECK (
            status IN (
                'TODO',
                'DOING',
                'BLOCKED',
                'DONE'
            )
        ),

    CONSTRAINT brain_tasks_priority_check
        CHECK (
            priority IN (
                'low',
                'normal',
                'high',
                'critical'
            )
        ),

    CONSTRAINT brain_tasks_completed_check
        CHECK (
            status <> 'DONE'
            OR completed_at IS NOT NULL
        )
);

CREATE INDEX idx_brain_tasks_project
ON public.brain_tasks(project_id);

CREATE INDEX idx_brain_tasks_status
ON public.brain_tasks(status);

CREATE INDEX idx_brain_tasks_priority
ON public.brain_tasks(priority);

CREATE INDEX idx_brain_tasks_created
ON public.brain_tasks(created_at DESC);

CREATE INDEX idx_brain_tasks_completed
ON public.brain_tasks(completed_at);

COMMENT ON TABLE public.brain_tasks IS
'Work items managed by Kao Brain.';

COMMENT ON COLUMN public.brain_tasks.dependencies IS
'Task dependencies represented as structured JSON references.';

COMMENT ON COLUMN public.brain_tasks.related_files IS
'Files related to the task.';

COMMENT ON COLUMN public.brain_tasks.related_features IS
'Application features related to the task.';

COMMENT ON COLUMN public.brain_tasks.related_decisions IS
'Decision references related to the task.';

COMMENT ON COLUMN public.brain_tasks.completion_criteria IS
'Criteria that determine whether the task is complete.';