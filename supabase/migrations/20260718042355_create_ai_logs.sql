CREATE TABLE public.ai_logs (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    prompt_id uuid
        REFERENCES public.ai_prompts(id)
        ON DELETE SET NULL,

    training_id uuid
        REFERENCES public.ai_training(id)
        ON DELETE SET NULL,

    entity_type text,

    entity_id uuid,

    model_name text NOT NULL,

    prompt_version integer NOT NULL DEFAULT 1,

    request_text text,

    response_text text,

    input_tokens integer NOT NULL DEFAULT 0,

    output_tokens integer NOT NULL DEFAULT 0,

    total_tokens integer GENERATED ALWAYS AS (
        input_tokens + output_tokens
    ) STORED,

    response_time_ms integer,

    status text NOT NULL DEFAULT 'success',

    error_message text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ai_logs_status_check
        CHECK (
            status IN (
                'success',
                'failed',
                'timeout',
                'cancelled'
            )
        ),

    CONSTRAINT ai_logs_tokens_check
        CHECK (
            input_tokens >= 0
            AND output_tokens >= 0
        ),

    CONSTRAINT ai_logs_response_time_check
        CHECK (
            response_time_ms IS NULL
            OR response_time_ms >= 0
        )

);

CREATE INDEX idx_ai_logs_profile
ON public.ai_logs(profile_id);

CREATE INDEX idx_ai_logs_prompt
ON public.ai_logs(prompt_id);

CREATE INDEX idx_ai_logs_training
ON public.ai_logs(training_id);

CREATE INDEX idx_ai_logs_entity
ON public.ai_logs(entity_type, entity_id);

CREATE INDEX idx_ai_logs_created
ON public.ai_logs(created_at DESC);

CREATE INDEX idx_ai_logs_status
ON public.ai_logs(status);

ALTER TABLE public.ai_logs
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System manage ai logs"
ON public.ai_logs
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.ai_logs IS
'Stores AI request logs, responses, token usage, and execution metadata.';