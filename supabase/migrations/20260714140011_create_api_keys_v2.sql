-- ==========================================
-- Table: api_keys
-- ==========================================

CREATE TABLE public.api_keys (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    key_name text NOT NULL,

    api_key text NOT NULL UNIQUE,

    api_secret text NOT NULL,

    permissions text[] NOT NULL DEFAULT '{}',

    last_used_at timestamptz,

    expires_at timestamptz,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER trg_api_keys_updated_at
BEFORE UPDATE ON public.api_keys
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_api_keys_profile
ON public.api_keys(profile_id);

CREATE INDEX idx_api_keys_active
ON public.api_keys(is_active);

CREATE INDEX idx_api_keys_last_used
ON public.api_keys(last_used_at);

CREATE INDEX idx_api_keys_expires
ON public.api_keys(expires_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own api keys"
ON public.api_keys
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Users can insert own api keys"
ON public.api_keys
FOR INSERT
TO authenticated
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "Users can update own api keys"
ON public.api_keys
FOR UPDATE
TO authenticated
USING (
    profile_id = auth.uid()
)
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "Users can delete own api keys"
ON public.api_keys
FOR DELETE
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Admins can manage api keys"
ON public.api_keys
FOR ALL
TO authenticated
USING (
    is_admin()
)
WITH CHECK (
    is_admin()
);