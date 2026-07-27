CREATE TABLE public.seller_statistics (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    seller_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    total_products integer NOT NULL DEFAULT 0,

    active_products integer NOT NULL DEFAULT 0,

    sold_products integer NOT NULL DEFAULT 0,

    total_orders integer NOT NULL DEFAULT 0,

    total_sales numeric(15,2) NOT NULL DEFAULT 0,

    total_views bigint NOT NULL DEFAULT 0,

    total_favorites bigint NOT NULL DEFAULT 0,

    total_reviews integer NOT NULL DEFAULT 0,

    average_rating numeric(3,2) NOT NULL DEFAULT 0,

    response_rate numeric(5,2) NOT NULL DEFAULT 100,

    response_time_seconds integer NOT NULL DEFAULT 0,

    cancellation_rate numeric(5,2) NOT NULL DEFAULT 0,

    return_rate numeric(5,2) NOT NULL DEFAULT 0,

    last_calculated_at timestamptz DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT seller_statistics_unique UNIQUE (seller_id)

);

CREATE INDEX idx_seller_statistics_seller
ON public.seller_statistics(seller_id);

CREATE INDEX idx_seller_statistics_sales
ON public.seller_statistics(total_sales DESC);

CREATE INDEX idx_seller_statistics_orders
ON public.seller_statistics(total_orders DESC);

CREATE INDEX idx_seller_statistics_rating
ON public.seller_statistics(average_rating DESC);

CREATE INDEX idx_seller_statistics_updated
ON public.seller_statistics(updated_at);

ALTER TABLE public.seller_statistics
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view seller statistics"
ON public.seller_statistics
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage seller statistics"
ON public.seller_statistics
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_seller_statistics_updated_at
BEFORE UPDATE
ON public.seller_statistics
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();