-- ==========================================
-- KaoSure Database V1.0
-- Table : reviews
-- ==========================================

CREATE TABLE public.reviews (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    shop_id uuid NOT NULL
        REFERENCES public.shops(id)
        ON DELETE CASCADE,

    reviewer_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    reviewee_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- good / bad
    review_type text NOT NULL,

    -- รีวิวจากผู้ซื้อ
    comment text,

    -- ผู้ขายตอบกลับ
    reply_comment text,

    reply_at timestamptz,

    -- Admin ซ่อนรีวิวได้
    is_visible boolean NOT NULL DEFAULT true,

    -- ผู้ซื้อแก้ไขรีวิวหรือยัง
    is_edited boolean NOT NULL DEFAULT false,

    edited_at timestamptz,

    -- ถูกรายงานหรือไม่
    report_count integer NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_reviews_order
ON public.reviews(order_id);

CREATE INDEX idx_reviews_product
ON public.reviews(product_id);

CREATE INDEX idx_reviews_shop
ON public.reviews(shop_id);

CREATE INDEX idx_reviews_reviewer
ON public.reviews(reviewer_id);

CREATE INDEX idx_reviews_reviewee
ON public.reviews(reviewee_id);

CREATE INDEX idx_reviews_type
ON public.reviews(review_type);

CREATE INDEX idx_reviews_visible
ON public.reviews(is_visible);

CREATE INDEX idx_reviews_created
ON public.reviews(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.reviews
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view reviews"
ON public.reviews
FOR SELECT
TO authenticated
USING (
    is_visible = true
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create review"
ON public.reviews
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = reviewer_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own review"
ON public.reviews
FOR UPDATE
TO authenticated
USING (
    auth.uid() = reviewer_id
);

-- ==========================================
-- END OF FILE
-- ==========================================