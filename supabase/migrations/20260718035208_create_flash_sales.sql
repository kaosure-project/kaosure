CREATE TABLE public.flash_sales (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    promotion_id uuid NOT NULL
        REFERENCES public.promotions(id)
        ON DELETE CASCADE,

    name text NOT NULL,

    starts_at timestamptz NOT NULL,

    ends_at timestamptz NOT NULL,

    max_orders integer,

    sold_count integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT flash_sales_unique
        UNIQUE (promotion_id),

    CONSTRAINT flash_sales_date_check
        CHECK (ends_at > starts_at),

    CONSTRAINT flash_sales_max_orders_check
        CHECK (
            max_orders IS NULL
            OR max_orders > 0
        ),

    CONSTRAINT flash_sales_sold_count_check
        CHECK (
            sold_count >= 0
        )

);

CREATE INDEX idx_flash_sales_promotion
ON public.flash_sales(promotion_id);

CREATE INDEX idx_flash_sales_active
ON public.flash_sales(is_active);

CREATE INDEX idx_flash_sales_period
ON public.flash_sales(starts_at, ends_at);

ALTER TABLE public.flash_sales
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active flash sales"
ON public.flash_sales
FOR SELECT
TO public
USING (is_active = true);

CREATE POLICY "System manage flash sales"
ON public.flash_sales
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_flash_sales_updated_at
BEFORE UPDATE
ON public.flash_sales
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.flash_sales IS
'Stores flash sale campaigns linked to promotions.';