-- ==========================================
-- KaoSure Database V1.0
-- Table : withdraw_requests
-- ==========================================

CREATE TABLE public.withdraw_requests (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    wallet_id uuid NOT NULL
        REFERENCES public.wallets(id)
        ON DELETE RESTRICT,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    amount numeric(12,2) NOT NULL,

    bank_name text NOT NULL,

    account_name text NOT NULL,

    account_number text NOT NULL,

    withdraw_status text NOT NULL DEFAULT 'pending',

    approved_at timestamptz,

    rejected_at timestamptz,

    paid_at timestamptz,

    reject_reason text,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_withdraw_wallet
ON public.withdraw_requests(wallet_id);

CREATE INDEX idx_withdraw_profile
ON public.withdraw_requests(profile_id);

CREATE INDEX idx_withdraw_status
ON public.withdraw_requests(withdraw_status);

CREATE INDEX idx_withdraw_created
ON public.withdraw_requests(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.withdraw_requests
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own withdraws"
ON public.withdraw_requests
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create withdraw"
ON public.withdraw_requests
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================