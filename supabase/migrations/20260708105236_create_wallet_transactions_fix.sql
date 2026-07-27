-- ==========================================
-- KaoSure Database V1.0
-- Table : wallet_transactions
-- ==========================================

CREATE TABLE public.wallet_transactions (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    wallet_id uuid NOT NULL
        REFERENCES public.wallets(id)
        ON DELETE CASCADE,

    order_id uuid
        REFERENCES public.orders(id)
        ON DELETE SET NULL,

    transaction_type text NOT NULL,

    amount numeric(12,2) NOT NULL,

    balance_before numeric(12,2) NOT NULL,

    balance_after numeric(12,2) NOT NULL,

    description text,

    transaction_status text NOT NULL DEFAULT 'completed',

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_wallet_transactions_wallet
ON public.wallet_transactions(wallet_id);

CREATE INDEX idx_wallet_transactions_order
ON public.wallet_transactions(order_id);

CREATE INDEX idx_wallet_transactions_type
ON public.wallet_transactions(transaction_type);

CREATE INDEX idx_wallet_transactions_created
ON public.wallet_transactions(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.wallet_transactions
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own wallet transactions"
ON public.wallet_transactions
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.wallets
        WHERE wallets.id = wallet_transactions.wallet_id
        AND wallets.profile_id = auth.uid()
    )
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "System can create wallet transactions"
ON public.wallet_transactions
FOR INSERT
TO authenticated
WITH CHECK (true);

-- ==========================================
-- END OF FILE
-- ==========================================