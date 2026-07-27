-- ==========================================
-- KaoSure Database V1.0
-- Table : notifications
-- ==========================================

CREATE TABLE public.notifications (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- หัวข้อแจ้งเตือน
    title text NOT NULL,

    -- รายละเอียด
    message text NOT NULL,

    -- ประเภทแจ้งเตือน
    -- order
    -- payment
    -- wallet
    -- escrow
    -- withdraw
    -- review
    -- favorite
    -- chat
    -- promotion
    -- report
    -- shop
    -- system
    notification_type text NOT NULL,

    -- UUID ของข้อมูลที่เกี่ยวข้อง
    target_id uuid,

    -- รูปประกอบ
    image_url text,

    -- Deep Link
    action_url text,

    -- ระดับความสำคัญ
    -- low
    -- normal
    -- high
    -- critical
    priority text NOT NULL DEFAULT 'normal',

    -- อ่านแล้วหรือยัง
    is_read boolean NOT NULL DEFAULT false,

    read_at timestamptz,

    -- ลบจากหน้าผู้ใช้แล้ว
    is_deleted boolean NOT NULL DEFAULT false,

    deleted_at timestamptz,

    -- วันหมดอายุของ Notification
    expires_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_notifications_profile
ON public.notifications(profile_id);

CREATE INDEX idx_notifications_type
ON public.notifications(notification_type);

CREATE INDEX idx_notifications_priority
ON public.notifications(priority);

CREATE INDEX idx_notifications_read
ON public.notifications(is_read);

CREATE INDEX idx_notifications_deleted
ON public.notifications(is_deleted);

CREATE INDEX idx_notifications_created
ON public.notifications(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.notifications
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "System can create notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (
    true
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete own notifications"
ON public.notifications
FOR DELETE
TO authenticated
USING (
    auth.uid() = profile_id
);

-- ==========================================
-- END OF FILE
-- ==========================================