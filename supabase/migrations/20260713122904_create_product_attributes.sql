-- ==========================================
-- TABLE: product_attributes
-- ==========================================

CREATE TABLE public.product_attributes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,

    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.product_attributes IS
'Stores available product attributes such as Color, Size, Storage, Material, etc.';

ALTER TABLE public.product_attributes
ADD CONSTRAINT product_attributes_slug_unique
UNIQUE (slug);

ALTER TABLE public.product_attributes
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read product attributes"
ON public.product_attributes
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can create product attributes"
ON public.product_attributes
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins can update product attributes"
ON public.product_attributes
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can delete product attributes"
ON public.product_attributes
FOR DELETE
TO authenticated
USING (true);