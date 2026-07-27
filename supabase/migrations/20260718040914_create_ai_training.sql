CREATE TABLE public.ai_training (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL,

    description text,

    training_type text NOT NULL,

    dataset_name text,

    prompt_id uuid
        REFERENCES public.ai_prompts(id)
        ON DELETE SET NULL,

    model_name text,

    status text NOT NULL DEFAULT 'pending',

    started_at timestamptz,

    completed_at timestamptz,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ai_training_type_check
        CHECK (
            training_type IN (
                'classification',
                'recommendation',
                'embedding',
                'moderation',
                'custom'
            )
        ),

    CONSTRAINT ai_training_status_check
        CHECK (
            status IN (
                'pending',
                'running',
                'completed',
                'failed',
                'cancelled'
            )
        ),

    CONSTRAINT ai_training_completed_check
        CHECK (
            completed_at IS NULL
            OR started_at IS NULL
            OR completed_at >= started_at
        )

);

CREATE INDEX idx_ai_training_prompt
ON public.ai_training(prompt_id);

CREATE INDEX idx_ai_training_status
ON public.ai_training(status);

CREATE INDEX idx_ai_training_type
ON public.ai_training(training_type);

CREATE INDEX idx_ai_training_model
ON public.ai_training(model_name);

CREATE INDEX idx_ai_training_created
ON public.ai_training(created_at DESC);

ALTER TABLE public.ai_training
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System manage ai training"
ON public.ai_training
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_ai_training_updated_at
BEFORE UPDATE
ON public.ai_training
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.ai_training IS
'Stores AI training jobs, datasets, and training results.';