CREATE TABLE public.saved_searches (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    keyword_id uuid NOT NULL
        REFERENCES public.search_keywords(id)
        ON DELETE CASCADE,

    search_name text,

    notify_new_results boolean NOT NULL DEFAULT false,

    last_checked_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT saved_searches_unique
        UNIQUE (profile_id, keyword_id)

);

CREATE INDEX idx_saved_searches_profile
ON public.saved_searches(profile_id);

CREATE INDEX idx_saved_searches_keyword
ON public.saved_searches(keyword_id);

CREATE INDEX idx_saved_searches_notify
ON public.saved_searches(notify_new_results);

ALTER TABLE public.saved_searches
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own saved searches"
ON public.saved_searches
FOR ALL
TO authenticated
USING (
    profile_id = auth.uid()
)
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "System manage saved searches"
ON public.saved_searches
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_saved_searches_updated_at
BEFORE UPDATE
ON public.saved_searches
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.saved_searches IS
'Stores users saved searches and optional search notifications.';