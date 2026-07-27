-- ==========================================
-- KaoSure Database V5.0
-- Table : product_comments
-- ==========================================

CREATE TABLE public.product_comments (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- สินค้า
    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    -- ผู้แสดงความคิดเห็น
    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- Reply (NULL = คอมเมนต์หลัก)
    parent_id uuid
        REFERENCES public.product_comments(id)
        ON DELETE CASCADE,

    -- ข้อความ
    comment text NOT NULL,

    -- เป็นเจ้าของสินค้าหรือไม่
    is_seller boolean NOT NULL DEFAULT false,

    -- ปักหมุดโดยผู้ขาย
    is_pinned boolean NOT NULL DEFAULT false,

    -- จำนวน Reply
    reply_count integer NOT NULL DEFAULT 0,

    -- แก้ไขแล้ว
    is_edited boolean NOT NULL DEFAULT false,

    edited_at timestamptz,

    -- ผู้ขายตอบล่าสุด
    seller_reply_at timestamptz,

    -- ซ่อนโดย Admin
    is_hidden boolean NOT NULL DEFAULT false,

    hidden_reason text,

    -- Soft Delete
    is_deleted boolean NOT NULL DEFAULT false,

    deleted_at timestamptz,

    -- Platform
    source text NOT NULL DEFAULT 'web',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    -- ==========================
    -- CHECK
    -- ==========================

    CONSTRAINT chk_comment_source
    CHECK (

        source IN (

            'web',
            'android',
            'ios',
            'admin',
            'api'

        )

    ),

    CONSTRAINT chk_reply_count
    CHECK (

        reply_count >= 0

    )

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_product_comments_product
ON public.product_comments(product_id);

CREATE INDEX idx_product_comments_profile
ON public.product_comments(profile_id);

CREATE INDEX idx_product_comments_parent
ON public.product_comments(parent_id);

CREATE INDEX idx_product_comments_created
ON public.product_comments(created_at DESC);

CREATE INDEX idx_product_comments_pinned
ON public.product_comments(is_pinned);

CREATE INDEX idx_product_comments_hidden
ON public.product_comments(is_hidden);

CREATE INDEX idx_product_comments_deleted
ON public.product_comments(is_deleted);

CREATE INDEX idx_product_comments_reply
ON public.product_comments(reply_count);

CREATE INDEX idx_product_comments_seller_reply
ON public.product_comments(seller_reply_at DESC);

-- ==========================================
-- RLS
-- ==========================================

ALTER TABLE public.product_comments
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view comments"
ON public.product_comments
FOR SELECT
TO authenticated
USING (

    true

);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create comments"
ON public.product_comments
FOR INSERT
TO authenticated
WITH CHECK (

    auth.uid() = profile_id

    AND EXISTS (

        SELECT 1

        FROM public.products

        WHERE

            products.id = product_comments.product_id

            AND products.status = 'active'

    )

);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own comments"
ON public.product_comments
FOR UPDATE
TO authenticated
USING (

    auth.uid() = profile_id

    AND EXISTS (

        SELECT 1

        FROM public.products

        WHERE

            products.id = product_comments.product_id

            AND products.status = 'active'

    )

);

-- ==========================================
-- END OF FILE
-- ==========================================