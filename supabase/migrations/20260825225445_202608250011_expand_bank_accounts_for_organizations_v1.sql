-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Organization Bank Account V1
-- Purpose   : Allow verified corporate bank accounts for Business KYC
-- ============================================================

ALTER TABLE public.bank_accounts
ADD COLUMN IF NOT EXISTS organization_id uuid
    REFERENCES public.organizations(id)
    ON DELETE CASCADE;

ALTER TABLE public.bank_accounts
ADD CONSTRAINT chk_bank_account_owner_exactly_one
CHECK (
    (profile_id IS NOT NULL AND organization_id IS NULL)
    OR
    (profile_id IS NULL AND organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_organization
ON public.bank_accounts(organization_id);

COMMENT ON COLUMN public.bank_accounts.organization_id
IS
'Organization that owns this bank account. Required for corporate/business bank accounts.';

COMMENT ON COLUMN public.bank_accounts.profile_id
IS
'Person profile that owns this bank account. Exactly one of profile_id or organization_id must be set.';
;
