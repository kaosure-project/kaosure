-- ==========================================
-- Table: webhooks
-- ==========================================

CREATE TABLE public.webhooks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    api_key_id uuid NOT NULL
        REFERENCES public.api_keys(id)
        ON DELETE CASCADE,

    name text NOT NULL,

    url text NOT NULL,

    secret text,

    events text[] NOT NULL DEFAULT '{}',

    is_active boolean NOT NULL DEFAULT true,

    last_called_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT webhooks_url_check
        CHECK (char_length(url) > 5)
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_webhooks_api_key
ON public.webhooks(api_key_id);

CREATE INDEX idx_webhooks_active
ON public.webhooks(is_active);

CREATE INDEX idx_webhooks_last_called
ON public.webhooks(last_called_at);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_webhooks_updated_at
BEFORE UPDATE
ON public.webhooks
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.webhooks ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own webhooks"
ON public.webhooks
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.api_keys ak
        WHERE ak.id = api_key_id
          AND ak.profile_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own webhooks"
ON public.webhooks
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.api_keys ak
        WHERE ak.id = api_key_id
          AND ak.profile_id = auth.uid()
    )
);

CREATE POLICY "Users can update own webhooks"
ON public.webhooks
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.api_keys ak
        WHERE ak.id = api_key_id
          AND ak.profile_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.api_keys ak
        WHERE ak.id = api_key_id
          AND ak.profile_id = auth.uid()
    )
);

CREATE POLICY "Users can delete own webhooks"
ON public.webhooks
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.api_keys ak
        WHERE ak.id = api_key_id
          AND ak.profile_id = auth.uid()
    )
);

CREATE POLICY "Admins can manage webhooks"
ON public.webhooks
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());