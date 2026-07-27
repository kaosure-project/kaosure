CREATE TABLE public.ai_prompts (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL UNIQUE,

    description text,

    prompt text NOT NULL,

    prompt_type text NOT NULL,

    version integer NOT NULL DEFAULT 1,

    model_name text,

    is_active boolean NOT NULL DEFAULT true,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ai_prompts_type_check
        CHECK (
            prompt_type IN (
                'system',
                'assistant',
                'classification',
                'translation',
                'recommendation',
                'moderation',
                'custom'
            )
        ),

    CONSTRAINT ai_prompts_version_check
        CHECK (
            version > 0
        )

);

CREATE INDEX idx_ai_prompts_name
ON public.ai_prompts(name);

CREATE INDEX idx_ai_prompts_type
ON public.ai_prompts(prompt_type);

CREATE INDEX idx_ai_prompts_active
ON public.ai_prompts(is_active);

ALTER TABLE public.ai_prompts
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System manage ai prompts"
ON public.ai_prompts
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_ai_prompts_updated_at
BEFORE UPDATE
ON public.ai_prompts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.ai_prompts IS
'Stores reusable AI prompts and prompt templates.';