CREATE TABLE public.promotions (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL,

    description text,

    promotion_type text NOT NULL,

    discount_type text NOT NULL,

    discount_value numeric(15,2) NOT NULL,

    minimum_purchase_amount numeric(15,2) DEFAULT 0,

    maximum_discount_amount numeric(15,2),

    starts_at timestamptz NOT NULL,

    ends_at timestamptz NOT NULL,

    is_active boolean NOT NULL DEFAULT true,

    priority integer NOT NULL DEFAULT 0,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT promotions_type_check
        CHECK (
            promotion_type IN (
                'campaign',
                'seasonal',
                'flash_sale',
                'clearance',
                'special'
            )
        ),

    CONSTRAINT promotions_discount_type_check
        CHECK (
            discount_type IN (
                'fixed',
                'percentage'
            )
        ),

    CONSTRAINT promotions_discount_value_check
        CHECK (
            discount_value > 0
        ),

    CONSTRAINT promotions_date_check
        CHECK (
            ends_at > starts_at
        )

);

CREATE INDEX idx_promotions_active
ON public.promotions(is_active);

CREATE INDEX idx_promotions_period
ON public.promotions(starts_at, ends_at);

CREATE INDEX idx_promotions_priority
ON public.promotions(priority);

CREATE INDEX idx_promotions_type
ON public.promotions(promotion_type);

ALTER TABLE public.promotions
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active promotions"
ON public.promotions
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "System manage promotions"
ON public.promotions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_promotions_updated_at
BEFORE UPDATE
ON public.promotions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.promotions IS
'Stores promotional campaigns and discount events.';