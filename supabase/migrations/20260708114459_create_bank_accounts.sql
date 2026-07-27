-- ==========================================
-- KaoSure Database V1.0
-- Table : bank_accounts
-- ==========================================

CREATE TABLE public.bank_accounts (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    bank_name text NOT NULL,

    account_name text NOT NULL,

    account_number text NOT NULL,

    is_default boolean NOT NULL DEFAULT false,

    is_verified boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_bank_accounts_profile
ON public.bank_accounts(profile_id);

CREATE INDEX idx_bank_accounts_default
ON public.bank_accounts(is_default);

CREATE INDEX idx_bank_accounts_active
ON public.bank_accounts(is_active);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.bank_accounts
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own bank accounts"
ON public.bank_accounts
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create own bank accounts"
ON public.bank_accounts
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own bank accounts"
ON public.bank_accounts
FOR UPDATE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete own bank accounts"
ON public.bank_accounts
FOR DELETE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================