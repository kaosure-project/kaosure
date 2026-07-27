-- =====================================================
-- Table : oauth_tokens
-- =====================================================

CREATE TABLE public.oauth_tokens (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    client_id uuid NOT NULL
        REFERENCES public.oauth_clients(id)
        ON DELETE CASCADE,

    access_token_hash text NOT NULL,

    refresh_token_hash text,

    token_type text NOT NULL DEFAULT 'Bearer',

    scopes text[] DEFAULT '{}',

    expires_at timestamptz NOT NULL,

    revoked_at timestamptz,

    last_used_at timestamptz,

    ip_address inet,

    user_agent text,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT oauth_tokens_token_type_check
    CHECK (token_type IN ('Bearer'))
);

-- =====================================================
-- Index
-- =====================================================

CREATE INDEX idx_oauth_tokens_profile
ON public.oauth_tokens(profile_id);

CREATE INDEX idx_oauth_tokens_client
ON public.oauth_tokens(client_id);

CREATE INDEX idx_oauth_tokens_expires
ON public.oauth_tokens(expires_at);

CREATE INDEX idx_oauth_tokens_last_used
ON public.oauth_tokens(last_used_at);

-- =====================================================
-- RLS
-- =====================================================

ALTER TABLE public.oauth_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own oauth tokens"
ON public.oauth_tokens
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "System manage oauth tokens"
ON public.oauth_tokens
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- =====================================================
-- Trigger
-- =====================================================

CREATE TRIGGER update_oauth_tokens_updated_at
BEFORE UPDATE
ON public.oauth_tokens
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();