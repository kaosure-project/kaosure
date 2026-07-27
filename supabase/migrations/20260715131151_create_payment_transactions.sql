-- ==========================================
-- Table: payment_transactions
-- ==========================================

CREATE TABLE public.payment_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    escrow_id uuid NOT NULL
        REFERENCES public.escrow_transactions(id)
        ON DELETE CASCADE,

    payer_wallet_id uuid
        REFERENCES public.wallets(id)
        ON DELETE SET NULL,

    receiver_wallet_id uuid
        REFERENCES public.wallets(id)
        ON DELETE SET NULL,

    payment_method_id uuid
        REFERENCES public.payment_methods(id)
        ON DELETE SET NULL,

    transaction_type text NOT NULL
        CHECK (
            transaction_type IN (
                'deposit',
                'payment',
                'release',
                'refund',
                'withdraw',
                'fee'
            )
        ),

    amount numeric(15,2) NOT NULL
        CHECK (amount >= 0),

    status text NOT NULL DEFAULT 'pending'
        CHECK (
            status IN (
                'pending',
                'processing',
                'completed',
                'failed',
                'cancelled'
            )
        ),

    reference_no text,

    note text,

    processed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_payment_transactions_escrow
ON public.payment_transactions(escrow_id);

CREATE INDEX idx_payment_transactions_payer
ON public.payment_transactions(payer_wallet_id);

CREATE INDEX idx_payment_transactions_receiver
ON public.payment_transactions(receiver_wallet_id);

CREATE INDEX idx_payment_transactions_status
ON public.payment_transactions(status);

CREATE INDEX idx_payment_transactions_created
ON public.payment_transactions(created_at);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_payment_transactions_updated_at
BEFORE UPDATE
ON public.payment_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.payment_transactions
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own payment transactions"
ON public.payment_transactions
FOR SELECT
TO authenticated
USING (
    payer_wallet_id IN (
        SELECT id FROM public.wallets
        WHERE profile_id = auth.uid()
    )
    OR
    receiver_wallet_id IN (
        SELECT id FROM public.wallets
        WHERE profile_id = auth.uid()
    )
);

CREATE POLICY "System can create payment transactions"
ON public.payment_transactions
FOR INSERT
TO service_role
WITH CHECK (true);

CREATE POLICY "System can update payment transactions"
ON public.payment_transactions
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can manage payment transactions"
ON public.payment_transactions
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());