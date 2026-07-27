-- ==========================================
-- KaoSure Database V1.0
-- Migration : 0001_create_profiles.sql
-- Description : User profile information
-- ==========================================

CREATE TABLE public.profiles (

    -- Primary Key (เชื่อมกับ auth.users)
    id UUID PRIMARY KEY
        REFERENCES auth.users(id)
        ON DELETE CASCADE,

    -- ชื่อที่แสดง
    display_name TEXT,

    -- ชื่อจริง
    first_name TEXT NOT NULL,

    -- นามสกุล
    last_name TEXT NOT NULL,

    -- รูปโปรไฟล์
    avatar_url TEXT,

    -- ระดับผู้ขาย
    seller_level TEXT NOT NULL DEFAULT 'standard',

    -- คะแนนความน่าเชื่อถือ
    trust_score INTEGER NOT NULL DEFAULT 0,

    -- เปิดร้านแล้วหรือยัง
    is_seller BOOLEAN NOT NULL DEFAULT FALSE,

    -- สถานะบัญชี
    account_status TEXT NOT NULL DEFAULT 'active',

    -- วันที่สร้าง
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- วันที่แก้ไขล่าสุด
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ตรวจสอบค่าที่อนุญาต
    CONSTRAINT seller_level_check
        CHECK (
            seller_level IN (
                'standard',
                'verified',
                'trusted',
                'licensed',
                'admin'
            )
        ),

    CONSTRAINT account_status_check
        CHECK (
            account_status IN (
                'active',
                'suspended',
                'banned',
                'closed'
            )
        )

);

COMMENT ON TABLE public.profiles IS 'User profile information';

COMMENT ON COLUMN public.profiles.id IS 'Reference to auth.users.id';
COMMENT ON COLUMN public.profiles.display_name IS 'Display name';
COMMENT ON COLUMN public.profiles.first_name IS 'First name';
COMMENT ON COLUMN public.profiles.last_name IS 'Last name';
COMMENT ON COLUMN public.profiles.avatar_url IS 'Profile image URL';
COMMENT ON COLUMN public.profiles.seller_level IS 'Seller level';
COMMENT ON COLUMN public.profiles.trust_score IS 'Trust score calculated by system';
COMMENT ON COLUMN public.profiles.is_seller IS 'Seller status';
COMMENT ON COLUMN public.profiles.account_status IS 'Account status';
COMMENT ON COLUMN public.profiles.created_at IS 'Created date';
COMMENT ON COLUMN public.profiles.updated_at IS 'Last updated date';

CREATE INDEX idx_profiles_seller_level
ON public.profiles(seller_level);

CREATE INDEX idx_profiles_account_status
ON public.profiles(account_status);
-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.profiles
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- SELECT
-- Users can read only their own profile
-- ==========================================

CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (
    auth.uid() = id
);

-- ==========================================
-- INSERT
-- Users can create only their own profile
-- ==========================================

CREATE POLICY "Users can insert own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = id
);

-- ==========================================
-- UPDATE
-- Users can update only their own profile
-- ==========================================

CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
    auth.uid() = id
)
WITH CHECK (
    auth.uid() = id
);

-- ==========================================
-- DELETE
-- No one can delete profile directly
-- ==========================================