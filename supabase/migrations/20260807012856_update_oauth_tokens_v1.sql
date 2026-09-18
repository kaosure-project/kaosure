-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update OAuth Tokens V1
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.oauth_tokens
ADD COLUMN IF NOT EXISTS access_token_expires_at timestamptz;

ALTER TABLE public.oauth_tokens
ADD COLUMN IF NOT EXISTS refresh_token_expires_at timestamptz;

ALTER TABLE public.oauth_tokens
ADD COLUMN IF NOT EXISTS device_id uuid;

ALTER TABLE public.oauth_tokens
ADD COLUMN IF NOT EXISTS revoked_by uuid;

ALTER TABLE public.oauth_tokens
ADD COLUMN IF NOT EXISTS revoke_reason text;

------------------------------------------------------------
-- Default values
------------------------------------------------------------

ALTER TABLE public.oauth_tokens
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.oauth_tokens
ALTER COLUMN updated_at SET DEFAULT now();

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_oauth_tokens_profile
ON public.oauth_tokens(profile_id);

CREATE INDEX IF NOT EXISTS idx_oauth_tokens_client
ON public.oauth_tokens(client_id);

CREATE INDEX IF NOT EXISTS idx_oauth_tokens_access_expire
ON public.oauth_tokens(access_token_expires_at);

CREATE INDEX IF NOT EXISTS idx_oauth_tokens_refresh_expire
ON public.oauth_tokens(refresh_token_expires_at);

------------------------------------------------------------
-- Foreign Keys
------------------------------------------------------------

ALTER TABLE public.oauth_tokens
DROP CONSTRAINT IF EXISTS oauth_tokens_device_fkey;

ALTER TABLE public.oauth_tokens
ADD CONSTRAINT oauth_tokens_device_fkey
FOREIGN KEY (device_id)
REFERENCES public.devices(id)
ON DELETE SET NULL;

ALTER TABLE public.oauth_tokens
DROP CONSTRAINT IF EXISTS oauth_tokens_revoked_by_fkey;

ALTER TABLE public.oauth_tokens
ADD CONSTRAINT oauth_tokens_revoked_by_fkey
FOREIGN KEY (revoked_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;