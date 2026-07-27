-- ==========================================
-- Table: dispute_logs
-- ==========================================

CREATE TABLE public.dispute_logs (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    dispute_id uuid NOT NULL
        REFERENCES public.disputes(id)
        ON DELETE CASCADE,

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    action text NOT NULL
        CHECK (
            action IN (
                'created',
                'updated',
                'message_sent',
                'file_uploaded',
                'assigned_admin',
                'status_changed',
                'resolved',
                'closed'
            )
        ),

    description text,

    metadata jsonb,

    ip_address inet,

    user_agent text,

    created_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.dispute_logs IS
'Stores audit logs and activity history for dispute cases.';

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_dispute_logs_dispute
ON public.dispute_logs(dispute_id);

CREATE INDEX idx_dispute_logs_profile
ON public.dispute_logs(profile_id);

CREATE INDEX idx_dispute_logs_action
ON public.dispute_logs(action);

CREATE INDEX idx_dispute_logs_created
ON public.dispute_logs(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.dispute_logs ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Admins can manage dispute logs"
ON public.dispute_logs
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.role = 'admin'
    )
);

CREATE POLICY "System can create dispute logs"
ON public.dispute_logs
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Users can view dispute logs"
ON public.dispute_logs
FOR SELECT
TO authenticated
USING (
    EXISTS (
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