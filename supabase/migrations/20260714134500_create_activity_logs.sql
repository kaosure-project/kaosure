-- ==========================================
-- Table: activity_logs
-- ==========================================

CREATE TABLE public.activity_logs (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    device_id uuid
        REFERENCES public.devices(id)
        ON DELETE SET NULL,

    action text NOT NULL,

    target_table text,

    target_id uuid,

    description text,

    ip_address inet,

    user_agent text,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_activity_logs_profile
ON public.activity_logs(profile_id);

CREATE INDEX idx_activity_logs_device
ON public.activity_logs(device_id);

CREATE INDEX idx_activity_logs_action
ON public.activity_logs(action);

CREATE INDEX idx_activity_logs_target
ON public.activity_logs(target_table,target_id);

CREATE INDEX idx_activity_logs_created
ON public.activity_logs(created_at);

CREATE INDEX idx_activity_logs_ip
ON public.activity_logs(ip_address);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own activity logs"
ON public.activity_logs
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Admins can manage activity logs"
ON public.activity_logs
FOR ALL
TO authenticated
USING (
    is_admin()
)
WITH CHECK (
    is_admin()
);