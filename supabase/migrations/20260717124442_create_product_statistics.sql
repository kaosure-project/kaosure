CREATE TABLE public.product_statistics (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    total_views bigint NOT NULL DEFAULT 0,
    total_favorites bigint NOT NULL DEFAULT 0,
    total_orders bigint NOT NULL DEFAULT 0,
    total_sales numeric(15,2) NOT NULL DEFAULT 0,

    total_reviews integer NOT NULL DEFAULT 0,
    average_rating numeric(3,2) NOT NULL DEFAULT 0,

    total_comments bigint NOT NULL DEFAULT 0,

    conversion_rate numeric(5,2) NOT NULL DEFAULT 0,

    last_viewed_at timestamptz,
    last_ordered_at timestamptz,
    last_favorited_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT unique_product_statistics
        UNIQUE(product_id),

    CONSTRAINT product_statistics_rating_check
        CHECK (
            average_rating >= 0
            AND average_rating <= 5
        ),

    CONSTRAINT product_statistics_conversion_check
        CHECK (
            conversion_rate >= 0
            AND conversion_rate <= 100
        )

);

CREATE INDEX idx_product_statistics_product
ON public.product_statistics(product_id);

CREATE INDEX idx_product_statistics_views
ON public.product_statistics(total_views DESC);

CREATE INDEX idx_product_statistics_sales
ON public.product_statistics(total_sales DESC);

CREATE INDEX idx_product_statistics_orders
ON public.product_statistics(total_orders DESC);

CREATE INDEX idx_product_statistics_rating
ON public.product_statistics(average_rating DESC);

CREATE INDEX idx_product_statistics_updated
ON public.product_statistics(updated_at);

ALTER TABLE public.product_statistics
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view product statistics"
ON public.product_statistics
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage product statistics"
ON public.product_statistics
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_product_statistics_updated_at
BEFORE UPDATE
ON public.product_statistics
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.product_statistics IS
'Aggregated product analytics and performance statistics.';