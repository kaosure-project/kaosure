-- ==========================================
-- KaoSure Database V1.0
-- Table : escrow_transactions
-- ==========================================

CREATE TABLE public.escrow_transactions (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    buyer_wallet_id uuid NOT NULL
        REFERENCES public.wallets(id)
        ON DELETE RESTRICT,

    seller_wallet_id uuid NOT NULL
        REFERENCES public.wallets(id)
        ON DELETE RESTRICT,

    amount numeric(12,2) NOT NULL,

    escrow_status text NOT NULL DEFAULT 'holding',

    released_at timestamptz,

    refunded_at timestamptz,

    disputed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_escrow_order
ON public.escrow_transactions(order_id);

CREATE INDEX idx_escrow_buyer_wallet
ON public.escrow_transactions(buyer_wallet_id);

CREATE INDEX idx_escrow_seller_wallet
ON public.escrow_transactions(seller_wallet_id);

CREATE INDEX idx_escrow_status
ON public.escrow_transactions(escrow_status);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.escrow_transactions
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own escrow"
ON public.escrow_transactions
FOR SELECT
TO authenticated
USING (

    EXISTS (
        SELECT 1
        FROM public.wallets
        WHERE wallets.id = escrow_transactions.buyer_wallet_id
        AND wallets.profile_id = auth.uid()
    )

    OR

    EXISTS (
        SELECT 1
        FROM public.wallets
        WHERE wallets.id = escrow_transactions.seller_wallet_id
        AND wallets.profile_id = auth.uid()
    )

);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "System can create escrow"
ON public.escrow_transactions
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "System can update escrow"
ON public.escrow_transactions
FOR UPDATE
TO authenticated
USING (true);

-- ==========================================
-- END OF FILE
-- ==========================================