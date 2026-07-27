-- ==========================================
-- KaoSure Database V1.0
-- Table : wallets
-- ==========================================

CREATE TABLE public.wallets (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    balance numeric(12,2) NOT NULL DEFAULT 0,

    hold_balance numeric(12,2) NOT NULL DEFAULT 0,

    currency text NOT NULL DEFAULT 'THB',

    wallet_status text NOT NULL DEFAULT 'active',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT wallets_profile_unique UNIQUE(profile_id)

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_wallets_profile
ON public.wallets(profile_id);

CREATE INDEX idx_wallets_status
ON public.wallets(wallet_status);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.wallets
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own wallet"
ON public.wallets
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create own wallet"
ON public.wallets
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own wallet"
ON public.wallets
FOR UPDATE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================