CREATE TABLE public.recently_viewed (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    viewed_at timestamptz NOT NULL DEFAULT now(),

    view_count integer NOT NULL DEFAULT 1,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT recently_viewed_unique
        UNIQUE(profile_id, product_id),

    CONSTRAINT recently_viewed_view_count_check
        CHECK (view_count >= 1)

);

CREATE INDEX idx_recently_viewed_profile
ON public.recently_viewed(profile_id);

CREATE INDEX idx_recently_viewed_product
ON public.recently_viewed(product_id);

CREATE INDEX idx_recently_viewed_viewed_at
ON public.recently_viewed(viewed_at DESC);

ALTER TABLE public.recently_viewed
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own recently viewed"
ON public.recently_viewed
FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "System manage recently viewed"
ON public.recently_viewed
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_recently_viewed_updated_at
BEFORE UPDATE
ON public.recently_viewed
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.recently_viewed IS
'Stores recently viewed products for each user.';