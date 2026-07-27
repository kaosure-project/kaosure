CREATE TABLE public.search_history (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    keyword_id uuid NOT NULL
        REFERENCES public.search_keywords(id)
        ON DELETE RESTRICT,

    original_keyword text NOT NULL,

    result_count integer NOT NULL DEFAULT 0,

    searched_at timestamptz NOT NULL DEFAULT now(),

    ip_address inet,

    user_agent text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT search_history_original_keyword_check
        CHECK (
            length(trim(original_keyword)) > 0
        ),

    CONSTRAINT search_history_result_count_check
        CHECK (
            result_count >= 0
        )

);

CREATE INDEX idx_search_history_profile
ON public.search_history(profile_id);

CREATE INDEX idx_search_history_keyword
ON public.search_history(keyword_id);

CREATE INDEX idx_search_history_searched_at
ON public.search_history(searched_at DESC);

CREATE INDEX idx_search_history_result_count
ON public.search_history(result_count);

ALTER TABLE public.search_history
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own search history"
ON public.search_history
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Users create own search history"
ON public.search_history
FOR INSERT
TO authenticated
WITH CHECK (
    profile_id IS NULL
    OR profile_id = auth.uid()
);

CREATE POLICY "System manage search history"
ON public.search_history
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.search_history IS
'Stores user search history linked to normalized search keywords.';