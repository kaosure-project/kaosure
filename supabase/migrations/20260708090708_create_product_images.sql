-- ==========================================
-- KaoSure Database V1.0
-- Table : product_images
-- ==========================================

CREATE TABLE public.product_images (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    image_url text NOT NULL,

    image_order integer NOT NULL DEFAULT 1,

    is_cover boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_product_images_product
ON public.product_images(product_id);

CREATE INDEX idx_product_images_cover
ON public.product_images(is_cover);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.product_images
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view product images"
ON public.product_images
FOR SELECT
TO authenticated
USING (true);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can upload product images"
ON public.product_images
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.products
        JOIN public.shops
          ON shops.id = products.shop_id
        WHERE products.id = product_images.product_id
          AND shops.owner_id = auth.uid()
    )
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update product images"
ON public.product_images
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.products
        JOIN public.shops
          ON shops.id = products.shop_id
        WHERE products.id = product_images.product_id
          AND shops.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.products
        JOIN public.shops
          ON shops.id = products.shop_id
        WHERE products.id = product_images.product_id
          AND shops.owner_id = auth.uid()
    )
);

-- ==========================================
-- END OF FILE
-- ==========================================