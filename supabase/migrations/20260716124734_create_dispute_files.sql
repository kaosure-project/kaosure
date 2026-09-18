-- ==========================================
-- Table: dispute_files
-- ==========================================

CREATE TABLE public.dispute_files (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    dispute_id uuid NOT NULL
        REFERENCES public.disputes(id)
        ON DELETE CASCADE,

    uploaded_by uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    file_name text NOT NULL,

    file_url text NOT NULL,

    file_type text NOT NULL
        CHECK (
            file_type IN (
                'image',
                'video',
                'document',
                'other'
            )
        ),

    file_size bigint,

    created_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.dispute_files IS
'Stores evidence files attached to dispute cases.';

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_dispute_files_dispute
ON public.dispute_files(dispute_id);

CREATE INDEX idx_dispute_files_uploaded_by
ON public.dispute_files(uploaded_by);

CREATE INDEX idx_dispute_files_created
ON public.dispute_files(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.dispute_files ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Admins can manage dispute files"
ON public.dispute_files
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.seller_level = 'admin'
    )
);

CREATE POLICY "Users can upload dispute files"
ON public.dispute_files
FOR INSERT
TO authenticated
WITH CHECK (
    uploaded_by = auth.uid()
);

CREATE POLICY "Users can view dispute files"
ON public.dispute_files
FOR SELECT
TO authenticated
USING (
    uploaded_by = auth.uid()
    OR EXISTS (
        SELECT 1
        FROM public.disputes d
        WHERE d.id = dispute_id
          AND (
                d.buyer_id = auth.uid()
             OR d.seller_id = auth.uid()
             OR d.created_by = auth.uid()
             OR d.admin_id = auth.uid()
          )
    )
);