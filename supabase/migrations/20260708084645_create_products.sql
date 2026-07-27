-- ==========================================
-- KaoSure Database V1.0
-- Table : products
-- ==========================================

CREATE TABLE public.products (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    shop_id uuid NOT NULL
        REFERENCES public.shops(id)
        ON DELETE CASCADE,

    category_id uuid NOT NULL
        REFERENCES public.categories(id)
        ON DELETE RESTRICT,

    title text NOT NULL,

    slug text NOT NULL UNIQUE,

    description text,

    condition_level smallint NOT NULL
        CHECK (condition_level BETWEEN 1 AND 6),

    price numeric(12,2) NOT NULL,

    stock integer NOT NULL DEFAULT 1,

    status text NOT NULL DEFAULT 'draft',

    is_active boolean NOT NULL DEFAULT true,

    view_count integer NOT NULL DEFAULT 0,

    favorite_count integer NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_products_shop
ON public.products(shop_id);

CREATE INDEX idx_products_category
ON public.products(category_id);

CREATE INDEX idx_products_slug
ON public.products(slug);

CREATE INDEX idx_products_status
ON public.products(status);

CREATE INDEX idx_products_active
ON public.products(is_active);

CREATE INDEX idx_products_price
ON public.products(price);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.products
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ทุกคนที่ Login ดูสินค้าได้
-- ==========================================

CREATE POLICY "Users can view products"
ON public.products
FOR SELECT
TO authenticated
USING (true);

-- ==========================================
-- POLICY : INSERT
-- เจ้าของร้านเพิ่มสินค้าได้เฉพาะร้านของตัวเอง
-- ==========================================

CREATE POLICY "Users can create products"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.shops
        WHERE shops.id = products.shop_id
          AND shops.owner_id = auth.uid()
    )
);

-- ==========================================
-- POLICY : UPDATE
-- เจ้าของร้านแก้สินค้าได้เฉพาะร้านของตัวเอง
-- ==========================================

CREATE POLICY "Users can update products"
ON public.products
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.shops
        WHERE shops.id = products.shop_id
          AND shops.owner_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.shops
        WHERE shops.id = products.shop_id
          AND shops.owner_id = auth.uid()
    )
);

-- ==========================================
-- END OF FILE
-- ==========================================