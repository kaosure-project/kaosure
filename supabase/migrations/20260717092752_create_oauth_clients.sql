-- ===========================================
-- Table : oauth_clients
-- ===========================================

CREATE TABLE public.oauth_clients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    client_name text NOT NULL,
    client_key text NOT NULL UNIQUE,
    client_secret text NOT NULL,

    platform_id uuid
        REFERENCES public.platforms(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    redirect_uri text,
    homepage text,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT oauth_clients_name_check
        CHECK (length(client_name) >= 2),

    CONSTRAINT oauth_clients_key_check
        CHECK (length(client_key) >= 16),

    CONSTRAINT oauth_clients_secret_check
        CHECK (length(client_secret) >= 32)
);

-- ===========================================
-- Index
-- ===========================================

CREATE INDEX idx_oauth_clients_platform
ON public.oauth_clients(platform_id);

CREATE INDEX idx_oauth_clients_key
ON public.oauth_clients(client_key);

CREATE INDEX idx_oauth_clients_active
ON public.oauth_clients(is_active);

CREATE INDEX idx_oauth_clients_created
ON public.oauth_clients(created_at);

-- ===========================================
-- RLS
-- ===========================================

ALTER TABLE public.oauth_clients
ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- Policies
-- ===========================================

CREATE POLICY "Admins manage oauth clients"
ON public.oauth_clients
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.seller_level = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.seller_level = 'admin'
    )
);

CREATE POLICY "Authenticated users view active oauth clients"
ON public.oauth_clients
FOR SELECT
TO authenticated
USING (
    is_active = true
);

-- ===========================================
-- Trigger
-- ===========================================

CREATE TRIGGER update_oauth_clients_updated_at
BEFORE UPDATE
ON public.oauth_clients
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();