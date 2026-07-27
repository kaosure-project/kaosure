-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : product_variants
-- Description : Stores product variants with individual SKU,
--               stock, barcode and pricing.
-- ============================================================

CREATE TABLE public.product_variants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL,

    sku text NOT NULL,

    barcode text,

    variant_name text,

    price numeric(12,2) NOT NULL DEFAULT 0,

    sale_price numeric(12,2),

    cost_price numeric(12,2) NOT NULL DEFAULT 0,

    stock integer NOT NULL DEFAULT 0,

    weight numeric(10,2),

    is_default boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT product_variants_product_fkey
        FOREIGN KEY (product_id)
        REFERENCES public.products(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- ============================================================
-- UNIQUE
-- ============================================================

ALTER TABLE public.product_variants
ADD CONSTRAINT product_variants_sku_unique
UNIQUE (sku);

ALTER TABLE public.product_variants
ADD CONSTRAINT product_variants_barcode_unique
UNIQUE (barcode);

-- ============================================================
-- INDEX
-- ============================================================

CREATE INDEX idx_product_variants_product
ON public.product_variants(product_id);

CREATE INDEX idx_product_variants_active
ON public.product_variants(is_active);

CREATE INDEX idx_product_variants_default
ON public.product_variants(is_default);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.product_variants IS
'Stores product variants with individual stock, SKU and pricing.';

COMMENT ON COLUMN public.product_variants.variant_name IS
'Example: Black / 128GB / XL';

COMMENT ON COLUMN public.product_variants.stock IS
'Current available stock.';

COMMENT ON COLUMN public.product_variants.cost_price IS
'Purchase cost.';

COMMENT ON COLUMN public.product_variants.sale_price IS
'Discount selling price.';

-- ============================================================
-- ENABLE RLS
-- ============================================================

ALTER TABLE public.product_variants
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICIES
-- ============================================================

CREATE POLICY "Authenticated users can read product variants"
ON public.product_variants
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can create product variants"
ON public.product_variants
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins can update product variants"
ON public.product_variants
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can delete product variants"
ON public.product_variants
FOR DELETE
TO authenticated
USING (true);