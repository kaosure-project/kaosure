-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Setup Identity Triggers V1
-- ==========================================================

------------------------------------------------------------
-- Generic updated_at trigger
------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

------------------------------------------------------------
-- profiles
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_profiles_updated_at
ON public.profiles;

CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE
ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- devices
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_devices_updated_at
ON public.devices;

CREATE TRIGGER trg_devices_updated_at
BEFORE UPDATE
ON public.devices
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- user_blocks
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_user_blocks_updated_at
ON public.user_blocks;

CREATE TRIGGER trg_user_blocks_updated_at
BEFORE UPDATE
ON public.user_blocks
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- bank_accounts
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_bank_accounts_updated_at
ON public.bank_accounts;

CREATE TRIGGER trg_bank_accounts_updated_at
BEFORE UPDATE
ON public.bank_accounts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- oauth_clients
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_oauth_clients_updated_at
ON public.oauth_clients;

CREATE TRIGGER trg_oauth_clients_updated_at
BEFORE UPDATE
ON public.oauth_clients
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- oauth_tokens
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_oauth_tokens_updated_at
ON public.oauth_tokens;

CREATE TRIGGER trg_oauth_tokens_updated_at
BEFORE UPDATE
ON public.oauth_tokens
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- sessions
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_sessions_updated_at
ON public.sessions;

CREATE TRIGGER trg_sessions_updated_at
BEFORE UPDATE
ON public.sessions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

------------------------------------------------------------
-- identity_documents
------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_identity_documents_updated_at
ON public.identity_documents;

CREATE TRIGGER trg_identity_documents_updated_at
BEFORE UPDATE
ON public.identity_documents
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();