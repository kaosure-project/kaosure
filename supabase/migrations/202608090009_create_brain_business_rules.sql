-- ============================================================
-- Kao Brain
-- Table: brain_business_rules
-- Purpose: Business rules governing a Brain project
-- ============================================================

CREATE TABLE public.brain_business_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    project_id UUID NOT NULL
        REFERENCES public.brain_projects(id)
        ON DELETE CASCADE,

    title TEXT NOT NULL,

    rule TEXT NOT NULL,

    reason TEXT,

    scope TEXT,

    status TEXT NOT NULL DEFAULT 'Proposed',

    approved_by UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    approved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brain_business_rules_status_check
        CHECK (
            status IN (
                'Proposed',
                'Active',
                'Deprecated',
                'Superseded'
            )
        ),

    CONSTRAINT brain_business_rules_approved_check
        CHECK (
            status <> 'Active'
            OR (
                approved_by IS NOT NULL
                AND approved_at IS NOT NULL
            )
        )
);

CREATE INDEX idx_brain_business_rules_project
ON public.brain_business_rules(project_id);

CREATE INDEX idx_brain_business_rules_status
ON public.brain_business_rules(status);

CREATE INDEX idx_brain_business_rules_approved_by
ON public.brain_business_rules(approved_by);

CREATE INDEX idx_brain_business_rules_created
ON public.brain_business_rules(created_at DESC);

COMMENT ON TABLE public.brain_business_rules IS
'Business rules governing a Kao Brain project. Active rules require approval.';

COMMENT ON COLUMN public.brain_business_rules.rule IS
'Business rule that governs project or system behavior.';

COMMENT ON COLUMN public.brain_business_rules.scope IS
'Scope in which the business rule applies.';

COMMENT ON COLUMN public.brain_business_rules.approved_by IS
'Profile that approved the business rule.';

COMMENT ON COLUMN public.brain_business_rules.approved_at IS
'Timestamp when the business rule was approved.';