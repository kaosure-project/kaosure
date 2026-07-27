CREATE TABLE public.promotion_products (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    promotion_id uuid NOT NULL
        REFERENCES public.promotions(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    special_price numeric(15,2),

    discount_value numeric(15,2),

    display_order integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    starts_at timestamptz,

    ends_at timestamptz,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT promotion_products_unique
        UNIQUE (promotion_id, product_id),

    CONSTRAINT promotion_products_price_check
        CHECK (
            special_price IS NULL
            OR special_price >= 0
        ),

    CONSTRAINT promotion_products_discount_check
        CHECK (
            discount_value IS NULL
            OR discount_value >= 0
        ),

    CONSTRAINT promotion_products_date_check
        CHECK (
            ends_at IS NULL
            OR starts_at IS NULL
            OR ends_at >= starts_at
        )

);

CREATE INDEX idx_promotion_products_promotion
ON public.promotion_products(promotion_id);

CREATE INDEX idx_promotion_products_product
ON public.promotion_products(product_id);

CREATE INDEX idx_promotion_products_active
ON public.promotion_products(is_active);

CREATE INDEX idx_promotion_products_period
ON public.promotion_products(starts_at, ends_at);

ALTER TABLE public.promotion_products
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active promotion products"
ON public.promotion_products
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "System manage promotion products"
ON public.promotion_products
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_promotion_products_updated_at
BEFORE UPDATE
ON public.promotion_products
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.promotion_products IS
'Maps products to promotional campaigns.';