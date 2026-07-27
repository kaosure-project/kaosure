CREATE TABLE public.sales_statistics (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    statistic_date date NOT NULL,

    total_orders bigint NOT NULL DEFAULT 0,
    completed_orders bigint NOT NULL DEFAULT 0,
    cancelled_orders bigint NOT NULL DEFAULT 0,
    refunded_orders bigint NOT NULL DEFAULT 0,

    gross_sales numeric(15,2) NOT NULL DEFAULT 0,
    net_sales numeric(15,2) NOT NULL DEFAULT 0,

    total_shipping_fee numeric(15,2) NOT NULL DEFAULT 0,
    total_platform_fee numeric(15,2) NOT NULL DEFAULT 0,

    average_order_value numeric(15,2) NOT NULL DEFAULT 0,

    total_buyers bigint NOT NULL DEFAULT 0,
    total_sellers bigint NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT unique_sales_statistics_date
        UNIQUE(statistic_date),

    CONSTRAINT gross_sales_check
        CHECK(gross_sales >= 0),

    CONSTRAINT net_sales_check
        CHECK(net_sales >= 0)

);

CREATE INDEX idx_sales_statistics_date
ON public.sales_statistics(statistic_date DESC);

CREATE INDEX idx_sales_statistics_gross
ON public.sales_statistics(gross_sales DESC);

CREATE INDEX idx_sales_statistics_net
ON public.sales_statistics(net_sales DESC);

CREATE INDEX idx_sales_statistics_updated
ON public.sales_statistics(updated_at);

ALTER TABLE public.sales_statistics
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view sales statistics"
ON public.sales_statistics
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage sales statistics"
ON public.sales_statistics
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_sales_statistics_updated_at
BEFORE UPDATE
ON public.sales_statistics
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.sales_statistics IS
'Aggregated marketplace sales analytics.';