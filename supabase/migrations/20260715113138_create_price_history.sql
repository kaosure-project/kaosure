-- ==========================================
-- Table: price_history
-- ==========================================

CREATE TABLE public.price_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    old_price numeric(12,2),

    new_price numeric(12,2) NOT NULL,

    changed_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    reason text,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT price_history_price_check
        CHECK (new_price >= 0)
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_price_history_product
ON public.price_history(product_id);

CREATE INDEX idx_price_history_changed_by
ON public.price_history(changed_by);

CREATE INDEX idx_price_history_created
ON public.price_history(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.price_history
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Everyone can view price history"
ON public.price_history
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can manage price history"
ON public.price_history
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());