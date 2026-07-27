CREATE TABLE public.coupons (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    code text NOT NULL UNIQUE,

    name text NOT NULL,

    description text,

    discount_type text NOT NULL,

    discount_value numeric(15,2) NOT NULL,

    minimum_order_amount numeric(15,2) NOT NULL DEFAULT 0,

    maximum_discount_amount numeric(15,2),

    usage_limit integer,

    usage_count integer NOT NULL DEFAULT 0,

    usage_limit_per_user integer NOT NULL DEFAULT 1,

    starts_at timestamptz NOT NULL,

    ends_at timestamptz NOT NULL,

    is_active boolean NOT NULL DEFAULT true,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT coupons_discount_type_check
        CHECK (
            discount_type IN (
                'fixed',
                'percentage'
            )
        ),

    CONSTRAINT coupons_discount_value_check
        CHECK (
            discount_value > 0
        ),

    CONSTRAINT coupons_date_check
        CHECK (
            ends_at > starts_at
        )

);

CREATE INDEX idx_coupons_code
ON public.coupons(code);

CREATE INDEX idx_coupons_active
ON public.coupons(is_active);

CREATE INDEX idx_coupons_period
ON public.coupons(starts_at, ends_at);

CREATE INDEX idx_coupons_created_by
ON public.coupons(created_by);

ALTER TABLE public.coupons
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active coupons"
ON public.coupons
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "System manage coupons"
ON public.coupons
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_coupons_updated_at
BEFORE UPDATE
ON public.coupons
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.coupons IS
'Stores coupon definitions, discount rules, and coupon validity settings.';