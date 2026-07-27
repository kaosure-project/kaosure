CREATE TABLE public.popular_searches (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    keyword_id uuid NOT NULL
        REFERENCES public.search_keywords(id)
        ON DELETE CASCADE,

    period_type text NOT NULL DEFAULT 'daily',

    period_date date NOT NULL,

    search_count bigint NOT NULL DEFAULT 0,

    rank integer,

    trend_score numeric(8,2) NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT popular_searches_period_type_check
        CHECK (
            period_type IN (
                'daily',
                'weekly',
                'monthly',
                'yearly'
            )
        ),

    CONSTRAINT popular_searches_search_count_check
        CHECK (search_count >= 0),

    CONSTRAINT popular_searches_unique
        UNIQUE (keyword_id, period_type, period_date)

);

CREATE INDEX idx_popular_searches_keyword
ON public.popular_searches(keyword_id);

CREATE INDEX idx_popular_searches_period
ON public.popular_searches(period_type, period_date);

CREATE INDEX idx_popular_searches_rank
ON public.popular_searches(rank);

CREATE INDEX idx_popular_searches_trend
ON public.popular_searches(trend_score DESC);

ALTER TABLE public.popular_searches
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view popular searches"
ON public.popular_searches
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage popular searches"
ON public.popular_searches
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_popular_searches_updated_at
BEFORE UPDATE
ON public.popular_searches
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.popular_searches IS
'Stores aggregated popular search keywords and trending search statistics.';