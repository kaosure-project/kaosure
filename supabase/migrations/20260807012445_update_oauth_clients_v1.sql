-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update OAuth Clients V1
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS description text;

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS client_type text DEFAULT 'first_party';

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS logo_url text;

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS callback_logout_uri text;

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS allowed_scopes text[];

ALTER TABLE public.oauth_clients
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

------------------------------------------------------------
-- Default values
------------------------------------------------------------

ALTER TABLE public.oauth_clients
ALTER COLUMN is_active SET DEFAULT true;

ALTER TABLE public.oauth_clients
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.oauth_clients
ALTER COLUMN updated_at SET DEFAULT now();

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_oauth_clients_platform
ON public.oauth_clients(platform_id);

CREATE INDEX IF NOT EXISTS idx_oauth_clients_status
ON public.oauth_clients(status);

CREATE INDEX IF NOT EXISTS idx_oauth_clients_active
ON public.oauth_clients(is_active);

------------------------------------------------------------
-- Foreign Key
------------------------------------------------------------

ALTER TABLE public.oauth_clients
DROP CONSTRAINT IF EXISTS oauth_clients_created_by_fkey;

ALTER TABLE public.oauth_clients
ADD CONSTRAINT oauth_clients_created_by_fkey
FOREIGN KEY (created_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;