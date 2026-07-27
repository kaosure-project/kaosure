CREATE TABLE public.coupon_usage (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    coupon_id uuid NOT NULL
        REFERENCES public.coupons(id)
        ON DELETE RESTRICT,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    order_id uuid
        REFERENCES public.orders(id)
        ON DELETE SET NULL,

    discount_amount numeric(15,2) NOT NULL,

    original_order_amount numeric(15,2) NOT NULL,

    final_order_amount numeric(15,2) NOT NULL,

    used_at timestamptz NOT NULL DEFAULT now(),

    status text NOT NULL DEFAULT 'used',

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT coupon_usage_status_check
        CHECK (
            status IN (
                'used',
                'cancelled',
                'refunded'
            )
        ),

    CONSTRAINT coupon_usage_discount_check
        CHECK (discount_amount >= 0),

    CONSTRAINT coupon_usage_amount_check
        CHECK (
            final_order_amount >= 0
            AND original_order_amount >= final_order_amount
        )

);

CREATE INDEX idx_coupon_usage_coupon
ON public.coupon_usage(coupon_id);

CREATE INDEX idx_coupon_usage_profile
ON public.coupon_usage(profile_id);

CREATE INDEX idx_coupon_usage_order
ON public.coupon_usage(order_id);

CREATE INDEX idx_coupon_usage_used_at
ON public.coupon_usage(used_at DESC);

ALTER TABLE public.coupon_usage
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own coupon usage"
ON public.coupon_usage
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "System manage coupon usage"
ON public.coupon_usage
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.coupon_usage IS
'Stores coupon redemption history and usage records.';