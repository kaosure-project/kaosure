-- ==========================================
-- KaoSure Database V1.0
-- Table : comment_reports
-- ==========================================

CREATE TABLE public.comment_reports (

    -- Primary Key
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- คอมเมนต์ที่ถูกรายงาน
    comment_id uuid NOT NULL
        REFERENCES public.product_comments(id)
        ON DELETE CASCADE,

    -- ผู้รายงาน
    reporter_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    -- เหตุผล
    report_type text NOT NULL,

    -- รายละเอียดเพิ่มเติม
    description text,

    -- สถานะ
    report_status text NOT NULL DEFAULT 'pending',

    -- ผู้ดูแลที่รับเรื่อง
    handled_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    -- หมายเหตุของแอดมิน
    admin_note text,

    -- วิธีจัดการ
    resolution_action text,

    -- ผู้ใช้เห็นข้อความสรุปหรือไม่
    is_visible_to_reporter boolean NOT NULL DEFAULT true,

    -- ข้อความแจ้งผล
    resolved_message text,

    -- ช่องทางที่ส่งรายงาน
    source text NOT NULL DEFAULT 'web',

    -- เวลาที่ดำเนินการ
    handled_at timestamptz,

    resolved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    -- ======================================
    -- CHECK CONSTRAINT
    -- ======================================

    CONSTRAINT chk_comment_report_source
    CHECK (
        source IN (
            'web',
            'android',
            'ios',
            'admin',
            'api'
        )
    ),

    CONSTRAINT chk_comment_report_status
    CHECK (
        report_status IN (
            'pending',
            'reviewing',
            'resolved',
            'rejected'
        )
    ),

    CONSTRAINT chk_comment_report_type
    CHECK (
        report_type IN (
            'spam',
            'abusive',
            'harassment',
            'fake_information',
            'off_topic',
            'illegal',
            'other'
        )
    ),

    -- 1 คน Report คอมเมนต์เดียวได้ครั้งเดียว
    CONSTRAINT uq_comment_report
    UNIQUE (
        comment_id,
        reporter_id
    )

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_comment_reports_comment
ON public.comment_reports(comment_id);

CREATE INDEX idx_comment_reports_reporter
ON public.comment_reports(reporter_id);

CREATE INDEX idx_comment_reports_status
ON public.comment_reports(report_status);

CREATE INDEX idx_comment_reports_created
ON public.comment_reports(created_at DESC);

CREATE INDEX idx_comment_reports_handled_by
ON public.comment_reports(handled_by);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.comment_reports
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ผู้รายงานดูได้เฉพาะของตัวเอง
-- ==========================================

CREATE POLICY "Users can view own comment reports"
ON public.comment_reports
FOR SELECT
TO authenticated
USING (

    auth.uid() = reporter_id

);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create comment reports"
ON public.comment_reports
FOR INSERT
TO authenticated
WITH CHECK (

    auth.uid() = reporter_id

);

-- ==========================================
-- POLICY : UPDATE
-- แก้ไขได้เฉพาะผู้รายงาน (ก่อนแอดมินดำเนินการ)
-- ==========================================

CREATE POLICY "Users can update own pending comment reports"
ON public.comment_reports
FOR UPDATE
TO authenticated
USING (

    auth.uid() = reporter_id

    AND report_status = 'pending'

);

-- ==========================================
-- END OF FILE
-- ==========================================