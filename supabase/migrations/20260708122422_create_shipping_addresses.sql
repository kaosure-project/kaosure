-- ==========================================
-- KaoSure Database V1.1
-- Table : shipping_addresses
-- ==========================================

CREATE TABLE public.shipping_addresses (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- ชื่อผู้รับ
    full_name text NOT NULL,

    -- เบอร์โทร
    phone_number text NOT NULL,

    -- ประเทศ
    country text NOT NULL,

    -- รหัสไปรษณีย์
    postal_code text NOT NULL,

    -- State (USA / Japan เป็นต้น)
    state text,

    -- จังหวัด
    province text NOT NULL,

    -- อำเภอ / City
    district text,

    -- ตำบล / Ward
    subdistrict text,

    -- บ้านเลขที่ ถนน
    address_line1 text NOT NULL,

    -- อาคาร ห้อง ชั้น
    address_line2 text,

    -- จุดสังเกต
    landmark text,

    -- หมายเหตุถึงขนส่ง
    -- เช่น
    -- โทรก่อนส่ง
    -- วางหน้าประตู
    -- ฝาก รปภ.
    -- ส่งหลัง 18:00
    delivery_note text,

    -- เลขประจำตัวผู้เสียภาษี
    -- รองรับการออกใบกำกับภาษีในอนาคต
    recipient_tax_id text,

    -- พิกัด
    latitude numeric(10,7),

    longitude numeric(10,7),

    -- บ้าน / ที่ทำงาน / อื่นๆ
    address_label text NOT NULL DEFAULT 'Home',

    -- ที่อยู่หลัก
    is_default boolean NOT NULL DEFAULT false,

    -- เปิดใช้งาน
    is_active boolean NOT NULL DEFAULT true,

    -- วันที่ใช้งานล่าสุด
    last_used_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_shipping_addresses_profile
ON public.shipping_addresses(profile_id);

CREATE INDEX idx_shipping_addresses_default
ON public.shipping_addresses(is_default);

CREATE INDEX idx_shipping_addresses_country
ON public.shipping_addresses(country);

CREATE INDEX idx_shipping_addresses_postal
ON public.shipping_addresses(postal_code);

CREATE INDEX idx_shipping_addresses_last_used
ON public.shipping_addresses(last_used_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.shipping_addresses
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own addresses"
ON public.shipping_addresses
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create own addresses"
ON public.shipping_addresses
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own addresses"
ON public.shipping_addresses
FOR UPDATE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete own addresses"
ON public.shipping_addresses
FOR DELETE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================