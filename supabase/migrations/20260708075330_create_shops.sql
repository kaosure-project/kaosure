-- ==========================================
-- KaoSure Database V1.0
-- Table : shops
-- ==========================================

CREATE TABLE public.shops (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    owner_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    shop_name text NOT NULL,

    shop_slug text NOT NULL UNIQUE,

    description text,

    logo_url text,

    banner_url text,

    country text NOT NULL DEFAULT 'TH',

    province text,

    district text,

    seller_level text NOT NULL DEFAULT 'standard',

    trust_score integer NOT NULL DEFAULT 0,

    follower_count integer NOT NULL DEFAULT 0,

    product_count integer NOT NULL DEFAULT 0,

    is_verified boolean NOT NULL DEFAULT false,

    shop_status text NOT NULL DEFAULT 'active',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_shops_owner
ON public.shops(owner_id);

CREATE INDEX idx_shops_slug
ON public.shops(shop_slug);

CREATE INDEX idx_shops_status
ON public.shops(shop_status);

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE public.shops
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ผู้ใช้ที่ Login สามารถดูร้านค้าได้
-- ==========================================

CREATE POLICY "Users can view shops"
ON public.shops
FOR SELECT
TO authenticated
USING (true);

-- ==========================================
-- POLICY : INSERT
-- เจ้าของสร้างร้านของตัวเองได้
-- ==========================================

CREATE POLICY "Users can create own shop"
ON public.shops
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = owner_id
);

-- ==========================================
-- POLICY : UPDATE
-- เจ้าของแก้ไขร้านของตัวเองได้
-- ==========================================

CREATE POLICY "Users can update own shop"
ON public.shops
FOR UPDATE
TO authenticated
USING (
    auth.uid() = owner_id
)
WITH CHECK (
    auth.uid() = owner_id
);

-- ==========================================
-- END OF FILE
-- ==========================================