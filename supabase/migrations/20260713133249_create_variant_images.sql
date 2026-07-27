-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : variant_images
-- ============================================================

CREATE TABLE public.variant_images (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    variant_id uuid NOT NULL,

    image_url text NOT NULL,

    display_order integer NOT NULL DEFAULT 0,

    is_primary boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.variant_images IS
'Stores images for each product variant.';

COMMENT ON COLUMN public.variant_images.variant_id IS
'Reference to product variant';

COMMENT ON COLUMN public.variant_images.image_url IS
'Image URL';

COMMENT ON COLUMN public.variant_images.display_order IS
'Image order';

COMMENT ON COLUMN public.variant_images.is_primary IS
'Primary image';

ALTER TABLE public.variant_images
ADD CONSTRAINT variant_images_variant_fkey
FOREIGN KEY (variant_id)
REFERENCES public.product_variants(id)
ON UPDATE CASCADE
ON DELETE CASCADE;

ALTER TABLE public.variant_images
ADD CONSTRAINT variant_images_variant_display_unique
UNIQUE (variant_id, display_order);

CREATE INDEX idx_variant_images_variant
ON public.variant_images(variant_id);

CREATE INDEX idx_variant_images_primary
ON public.variant_images(is_primary);

ALTER TABLE public.variant_images
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Policies
-- ============================================================

CREATE POLICY "Authenticated users can read variant images"
ON public.variant_images
FOR SELECT
TO authenticated
USING (
    true
);

CREATE POLICY "Admins can create variant images"
ON public.variant_images
FOR INSERT
TO authenticated
WITH CHECK (
    true
);

CREATE POLICY "Admins can update variant images"
ON public.variant_images
FOR UPDATE
TO authenticated
USING (
    true
)
WITH CHECK (
    true
);

CREATE POLICY "Admins can delete variant images"
ON public.variant_images
FOR DELETE
TO authenticated
USING (
    true
);