-- ==========================================
-- KaoSure Database V2.0
-- Table : reports
-- ==========================================

CREATE TABLE public.reports (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- เลขที่รายการแจ้งปัญหา
    -- RPT-20260708-000001
    report_number text UNIQUE,

    -- ผู้แจ้ง
    reporter_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- อ้างอิงคำสั่งซื้อ (ถ้ามี)
    order_id uuid
        REFERENCES public.orders(id)
        ON DELETE SET NULL,

    -- ประเภทของการแจ้ง
    -- product
    -- shop
    -- user
    -- review
    -- chat
    report_type text NOT NULL,

    -- UUID ของข้อมูลที่ถูกแจ้ง
    target_id uuid NOT NULL,

    -- เหตุผลหลัก
    reason text NOT NULL,

    -- รายละเอียดเพิ่มเติม
    description text,

    -- รูปหลักฐาน
    evidence_image_url text,

    -- สถานะ
    -- pending
    -- reviewing
    -- resolved
    -- rejected
    report_status text NOT NULL DEFAULT 'pending',

    -- ระดับความสำคัญ
    -- low
    -- normal
    -- high
    -- critical
    priority text NOT NULL DEFAULT 'normal',

    -- แหล่งที่มาของการแจ้ง
    -- web
    -- android
    -- ios
    -- admin
    -- api
    source text NOT NULL DEFAULT 'web',

    -- จำนวนการแจ้งเรื่องเดียวกัน
    duplicate_count integer NOT NULL DEFAULT 1,

    -- หมายเหตุของผู้ดูแล
    admin_note text,

    -- ผลการดำเนินการ
    -- warning
    -- listing_removed
    -- account_suspended
    -- account_banned
    -- no_violation
    resolution_action text,

    -- ข้อความตอบกลับผู้แจ้ง
    resolved_message text,

    -- ผู้แจ้งเห็นผลหรือไม่
    is_visible_to_reporter boolean NOT NULL DEFAULT true,

    -- เจ้าหน้าที่ผู้รับเรื่อง
    handled_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    -- เวลาเริ่มดำเนินการ
    handled_at timestamptz,

    -- เวลาปิดเรื่อง
    resolved_at timestamptz,

    -- Soft Delete
    is_deleted boolean NOT NULL DEFAULT false,

    deleted_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_reports_number
ON public.reports(report_number);

CREATE INDEX idx_reports_reporter
ON public.reports(reporter_id);

CREATE INDEX idx_reports_order
ON public.reports(order_id);

CREATE INDEX idx_reports_type
ON public.reports(report_type);

CREATE INDEX idx_reports_target
ON public.reports(target_id);

CREATE INDEX idx_reports_status
ON public.reports(report_status);

CREATE INDEX idx_reports_priority
ON public.reports(priority);

CREATE INDEX idx_reports_source
ON public.reports(source);

CREATE INDEX idx_reports_duplicate
ON public.reports(duplicate_count);

CREATE INDEX idx_reports_handled_by
ON public.reports(handled_by);

CREATE INDEX idx_reports_resolved
ON public.reports(resolved_at);

CREATE INDEX idx_reports_created
ON public.reports(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.reports
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own reports"
ON public.reports
FOR SELECT
TO authenticated
USING (
    auth.uid() = reporter_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create reports"
ON public.reports
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = reporter_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own reports"
ON public.reports
FOR UPDATE
TO authenticated
USING (
    auth.uid() = reporter_id
);

-- ==========================================
-- END OF FILE
-- ==========================================