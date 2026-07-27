-- ==========================================
-- KaoSure Database V1.0
-- Table : carts
-- ==========================================

CREATE TABLE public.carts (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    quantity integer NOT NULL DEFAULT 1
        CHECK (quantity > 0),

    created_at timestamptz NOT NULL DEFAULT now(),

    UNIQUE(user_id, product_id)

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_carts_user
ON public.carts(user_id);

CREATE INDEX idx_carts_product
ON public.carts(product_id);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.carts
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own cart"
ON public.carts
FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can add to own cart"
ON public.carts
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = user_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own cart"
ON public.carts
FOR UPDATE
TO authenticated
USING (
    auth.uid() = user_id
)
WITH CHECK (
    auth.uid() = user_id
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete own cart"
ON public.carts
FOR DELETE
TO authenticated
USING (
    auth.uid() = user_id
);

-- ==========================================
-- END OF FILE
-- ==========================================