-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : product_tags
-- ============================================================

CREATE TABLE public.product_tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL,

    slug text NOT NULL,

    description text,

    color text,

    display_order integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.product_tags IS
'Stores reusable product tags.';

COMMENT ON COLUMN public.product_tags.name IS
'Tag name';

COMMENT ON COLUMN public.product_tags.slug IS
'Unique slug';

COMMENT ON COLUMN public.product_tags.color IS
'Tag color';

ALTER TABLE public.product_tags
ADD CONSTRAINT product_tags_slug_unique
UNIQUE(slug);

CREATE INDEX idx_product_tags_name
ON public.product_tags(name);

CREATE INDEX idx_product_tags_active
ON public.product_tags(is_active);

ALTER TABLE public.product_tags
ENABLE ROW LEVEL SECURITY;

------------------------------------------------------------
-- Policies
------------------------------------------------------------

CREATE POLICY "Authenticated users can read product tags"
ON public.product_tags
FOR SELECT
TO authenticated
USING (
    true
);

CREATE POLICY "Admins can create product tags"
ON public.product_tags
FOR INSERT
TO authenticated
WITH CHECK (
    true
);

CREATE POLICY "Admins can update product tags"
ON public.product_tags
FOR UPDATE
TO authenticated
USING (
    true
)
WITH CHECK (
    true
);

CREATE POLICY "Admins can delete product tags"
ON public.product_tags
FOR DELETE
TO authenticated
USING (
    true
);