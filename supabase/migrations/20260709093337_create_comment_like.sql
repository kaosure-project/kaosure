-- ==========================================
-- KaoSure Database V2.0
-- Table : comment_likes
-- ==========================================

CREATE TABLE public.comment_likes (

    -- Primary Key
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Comment
    comment_id uuid NOT NULL
        REFERENCES public.product_comments(id)
        ON DELETE CASCADE,

    -- User who liked
    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- Platform
    -- web
    -- android
    -- ios
    -- admin
    -- api
    source text NOT NULL DEFAULT 'web',

    -- Created
    created_at timestamptz NOT NULL DEFAULT now(),

    -- ======================================
    -- CHECK CONSTRAINT
    -- ======================================

    CONSTRAINT chk_comment_like_source
    CHECK (
        source IN (
            'web',
            'android',
            'ios',
            'admin',
            'api'
        )
    ),

    -- 1 User Like ได้ครั้งเดียว
    CONSTRAINT uq_comment_like
    UNIQUE (
        comment_id,
        profile_id
    )

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_comment_likes_comment
ON public.comment_likes(comment_id);

CREATE INDEX idx_comment_likes_profile
ON public.comment_likes(profile_id);

CREATE INDEX idx_comment_likes_created
ON public.comment_likes(created_at DESC);

-- Query ที่ใช้บ่อยที่สุด
-- ตรวจว่าผู้ใช้นี้กด Like แล้วหรือยัง

CREATE INDEX idx_comment_likes_comment_profile
ON public.comment_likes(
    comment_id,
    profile_id
);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.comment_likes
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ทุกคนอ่านได้
-- ==========================================

CREATE POLICY "Users can view comment likes"
ON public.comment_likes
FOR SELECT
TO authenticated
USING (
    true
);

-- ==========================================
-- POLICY : INSERT
-- กด Like
-- ==========================================

CREATE POLICY "Users can like comments"
ON public.comment_likes
FOR INSERT
TO authenticated
WITH CHECK (

    auth.uid() = profile_id

);

-- ==========================================
-- POLICY : DELETE
-- ยกเลิก Like
-- ==========================================

CREATE POLICY "Users can unlike comments"
ON public.comment_likes
FOR DELETE
TO authenticated
USING (

    auth.uid() = profile_id

);

-- ==========================================
-- END OF FILE
-- ==========================================