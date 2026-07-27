-- ==========================================
-- KaoSure Database V1.0
-- Table : favorites
-- ==========================================

CREATE TABLE public.favorites (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT unique_favorite
        UNIQUE(profile_id, product_id)

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_favorites_profile
ON public.favorites(profile_id);

CREATE INDEX idx_favorites_product
ON public.favorites(product_id);

CREATE INDEX idx_favorites_created
ON public.favorites(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.favorites
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view favorites"
ON public.favorites
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create favorites"
ON public.favorites
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete favorites"
ON public.favorites
FOR DELETE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================