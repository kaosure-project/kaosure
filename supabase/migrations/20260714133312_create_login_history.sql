-- ==========================================
-- Table: login_history
-- ==========================================

CREATE TABLE public.login_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    device_id uuid
        REFERENCES public.devices(id)
        ON DELETE SET NULL,

    login_type text NOT NULL
        CHECK (
            login_type IN (
                'password',
                'google',
                'apple',
                'line',
                'facebook',
                'github',
                'anonymous'
            )
        ),

    ip_address inet,

    user_agent text,

    login_status text NOT NULL DEFAULT 'success'
        CHECK (
            login_status IN (
                'success',
                'failed',
                'blocked'
            )
        ),

    failure_reason text,

    country text,
    city text,

    logged_in_at timestamptz NOT NULL DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_login_history_profile
ON public.login_history(profile_id);

CREATE INDEX idx_login_history_device
ON public.login_history(device_id);

CREATE INDEX idx_login_history_status
ON public.login_history(login_status);

CREATE INDEX idx_login_history_time
ON public.login_history(logged_in_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.login_history ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own login history"
ON public.login_history
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Admins can manage login history"
ON public.login_history
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());