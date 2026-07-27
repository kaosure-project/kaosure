-- ==========================================
-- TABLE: brands
-- ==========================================

CREATE TABLE public.brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name TEXT NOT NULL,
    slug TEXT NOT NULL,

    logo_url TEXT,
    description TEXT,
    website TEXT,
    country TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.brands IS
'Stores product brands used for categorizing and filtering products.';

ALTER TABLE public.brands
ADD CONSTRAINT brands_slug_unique
UNIQUE (slug);

ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read brands"
ON public.brands
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can create brands"
ON public.brands
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins can update brands"
ON public.brands
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can delete brands"
ON public.brands
FOR DELETE
TO authenticated
USING (true);