CREATE TABLE public.search_keywords (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    keyword text NOT NULL UNIQUE,

    normalized_keyword text NOT NULL UNIQUE,

    search_count bigint NOT NULL DEFAULT 0,

    last_searched_at timestamptz,

    is_blocked boolean NOT NULL DEFAULT false,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT search_keywords_keyword_check
        CHECK (length(trim(keyword)) > 0),

    CONSTRAINT search_keywords_normalized_check
        CHECK (length(trim(normalized_keyword)) > 0)

);

CREATE INDEX idx_search_keywords_keyword
ON public.search_keywords(keyword);

CREATE INDEX idx_search_keywords_normalized
ON public.search_keywords(normalized_keyword);

CREATE INDEX idx_search_keywords_search_count
ON public.search_keywords(search_count DESC);

CREATE INDEX idx_search_keywords_last_searched
ON public.search_keywords(last_searched_at DESC);

ALTER TABLE public.search_keywords
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view search keywords"
ON public.search_keywords
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage search keywords"
ON public.search_keywords
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_search_keywords_updated_at
BEFORE UPDATE
ON public.search_keywords
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.search_keywords IS
'Stores normalized search keywords used throughout the marketplace search engine.';