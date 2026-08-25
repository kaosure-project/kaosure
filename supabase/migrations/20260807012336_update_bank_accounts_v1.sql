-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update Bank Accounts V1
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS account_type text;

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS currency_code text DEFAULT 'THB';

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS verified_at timestamptz;

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS verified_by uuid;

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

------------------------------------------------------------
-- Default values
------------------------------------------------------------

ALTER TABLE public.bank_accounts
ALTER COLUMN is_default SET DEFAULT false;

ALTER TABLE public.bank_accounts
ALTER COLUMN is_verified SET DEFAULT false;

ALTER TABLE public.bank_accounts
ALTER COLUMN is_active SET DEFAULT true;

ALTER TABLE public.bank_accounts
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.bank_accounts
ALTER COLUMN updated_at SET DEFAULT now();

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_bank_accounts_profile_id
ON public.bank_accounts(profile_id);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_bank_code
ON public.bank_accounts(bank_code);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_default
ON public.bank_accounts(is_default);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_verified
ON public.bank_accounts(is_verified);

------------------------------------------------------------
-- Foreign Key
------------------------------------------------------------

ALTER TABLE public.bank_accounts
DROP CONSTRAINT IF EXISTS bank_accounts_verified_by_fkey;

ALTER TABLE public.bank_accounts
ADD CONSTRAINT bank_accounts_verified_by_fkey
FOREIGN KEY (verified_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;