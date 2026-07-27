CREATE TABLE public.commission (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE RESTRICT,

    seller_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    buyer_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    commission_rate numeric(5,2) NOT NULL,

    order_amount numeric(15,2) NOT NULL,

    commission_amount numeric(15,2) NOT NULL,

    seller_amount numeric(15,2) NOT NULL,

    currency_code text NOT NULL DEFAULT 'THB',

    status text NOT NULL DEFAULT 'pending',

    settled_at timestamptz,

    notes text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT commission_status_check
        CHECK (
            status IN (
                'pending',
                'reserved',
                'settled',
                'cancelled',
                'refunded'
            )
        ),

    CONSTRAINT commission_rate_check
        CHECK (
            commission_rate >= 0
            AND commission_rate <= 100
        ),

    CONSTRAINT commission_amount_check
        CHECK (
            order_amount >= 0
            AND commission_amount >= 0
            AND seller_amount >= 0
        ),

    CONSTRAINT commission_unique_order
        UNIQUE (order_id)

);

CREATE INDEX idx_commission_order
ON public.commission(order_id);

CREATE INDEX idx_commission_seller
ON public.commission(seller_id);

CREATE INDEX idx_commission_buyer
ON public.commission(buyer_id);

CREATE INDEX idx_commission_status
ON public.commission(status);

CREATE INDEX idx_commission_settled_at
ON public.commission(settled_at DESC);

ALTER TABLE public.commission
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own commission records"
ON public.commission
FOR SELECT
TO authenticated
USING (
    seller_id = auth.uid()
    OR buyer_id = auth.uid()
);

CREATE POLICY "System manage commission"
ON public.commission
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_commission_updated_at
BEFORE UPDATE
ON public.commission
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.commission IS
'Stores marketplace commission records for completed orders and seller settlements.';