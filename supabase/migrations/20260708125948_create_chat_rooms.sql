-- ==========================================
-- KaoSure Database V2.1
-- Table : chat_rooms
-- ==========================================

CREATE TABLE public.chat_rooms (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- อ้างอิงออเดอร์
    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    -- ผู้ซื้อ
    buyer_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- ผู้ขาย
    seller_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- สินค้า
    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    -- ร้านค้า
    shop_id uuid NOT NULL
        REFERENCES public.shops(id)
        ON DELETE CASCADE,

    -- สถานะห้อง
    -- active
    -- archived
    -- closed
    room_status text NOT NULL DEFAULT 'active',

    -- จำนวนข้อความทั้งหมด
    message_count integer NOT NULL DEFAULT 0,

    -- จำนวนข้อความที่ผู้ซื้อยังไม่ได้อ่าน
    buyer_unread_count integer NOT NULL DEFAULT 0,

    -- จำนวนข้อความที่ผู้ขายยังไม่ได้อ่าน
    seller_unread_count integer NOT NULL DEFAULT 0,

    -- ผู้ส่งข้อความล่าสุด
    last_sender_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    -- ข้อความล่าสุด
    last_message_preview text,

    -- เวลาส่งข้อความล่าสุด
    last_message_at timestamptz,

    -- ปิดแจ้งเตือนห้อง
    is_muted boolean NOT NULL DEFAULT false,

    -- ห้องถูกล็อกโดยระบบ
    is_blocked boolean NOT NULL DEFAULT false,

    -- เหตุผลที่ล็อก
    blocked_reason text,

    -- เวลา Archive
    archived_at timestamptz,

    -- เวลาปิดห้อง
    closed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- UNIQUE
-- 1 Order = 1 Chat Room
-- ==========================================

CREATE UNIQUE INDEX uq_chat_rooms_order
ON public.chat_rooms(order_id);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_chat_rooms_order
ON public.chat_rooms(order_id);

CREATE INDEX idx_chat_rooms_buyer
ON public.chat_rooms(buyer_id);

CREATE INDEX idx_chat_rooms_seller
ON public.chat_rooms(seller_id);

CREATE INDEX idx_chat_rooms_product
ON public.chat_rooms(product_id);

CREATE INDEX idx_chat_rooms_shop
ON public.chat_rooms(shop_id);

CREATE INDEX idx_chat_rooms_status
ON public.chat_rooms(room_status);

CREATE INDEX idx_chat_rooms_last_sender
ON public.chat_rooms(last_sender_id);

CREATE INDEX idx_chat_rooms_last_message
ON public.chat_rooms(last_message_at DESC);

CREATE INDEX idx_chat_rooms_created
ON public.chat_rooms(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.chat_rooms
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Buyer and Seller can view chat room"
ON public.chat_rooms
FOR SELECT
TO authenticated
USING (

    auth.uid() = buyer_id

    OR

    auth.uid() = seller_id

);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Buyer can create chat room"
ON public.chat_rooms
FOR INSERT
TO authenticated
WITH CHECK (

    auth.uid() = buyer_id

);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Buyer and Seller can update chat room"
ON public.chat_rooms
FOR UPDATE
TO authenticated
USING (

    auth.uid() = buyer_id

    OR

    auth.uid() = seller_id

);

-- ==========================================
-- END OF FILE
-- ==========================================