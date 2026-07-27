-- ==========================================
-- Table: product_views
-- ==========================================

CREATE TABLE public.product_views (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    ip_address inet,

    user_agent text,

    viewed_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_product_views_product
ON public.product_views(product_id);

CREATE INDEX idx_product_views_profile
ON public.product_views(profile_id);

CREATE INDEX idx_product_views_viewed_at
ON public.product_views(viewed_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.product_views
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Admins can manage product views"
ON public.product_views
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

CREATE POLICY "Everyone can insert product views"
ON public.product_views
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Everyone can view product views"
ON public.product_views
FOR SELECT
TO authenticated
USING (true);