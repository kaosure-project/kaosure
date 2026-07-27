-- ==========================================
-- Fix: escrow_transactions
-- ==========================================

-- --------------------------
-- Amount CHECK
-- --------------------------

ALTER TABLE public.escrow_transactions
ADD CONSTRAINT escrow_transactions_amount_check
CHECK (amount >= 0);

-- --------------------------
-- Status CHECK
-- --------------------------

ALTER TABLE public.escrow_transactions
ADD CONSTRAINT escrow_transactions_status_check
CHECK (
    escrow_status IN (
        'holding',
        'released',
        'refunded',
        'disputed',
        'cancelled'
    )
);

-- --------------------------
-- updated_at Trigger
-- --------------------------

CREATE TRIGGER update_escrow_transactions_updated_at
BEFORE UPDATE
ON public.escrow_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();