-- ============================================================
-- KaoSure Platform
-- Table: sessions
-- Description:
-- Active login sessions for KaoSure Identity Platform.
-- Supports multi-device, multi-platform and future SSO.
-- ============================================================

CREATE TABLE public.sessions (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    device_id uuid
        REFERENCES public.devices(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    access_token_hash text NOT NULL,

    refresh_token_hash text,

    token_type text NOT NULL DEFAULT 'Bearer',

    platform text NOT NULL,

    ip_address inet,

    user_agent text,

    country text,

    city text,

    last_activity_at timestamptz NOT NULL DEFAULT now(),

    expires_at timestamptz NOT NULL,

    revoked_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.sessions IS
'Stores active login sessions for KaoSure Identity Platform across all devices and applications.';

-- ============================================================
-- Constraints
-- ============================================================

ALTER TABLE public.sessions
ADD CONSTRAINT sessions_access_token_unique
UNIQUE (access_token_hash);

ALTER TABLE public.sessions
ADD CONSTRAINT sessions_refresh_token_unique
UNIQUE (refresh_token_hash);

ALTER TABLE public.sessions
ADD CONSTRAINT sessions_platform_check
CHECK (
    platform IN (
        'web',
        'android',
        'ios',
        'desktop'
    )
);

ALTER TABLE public.sessions
ADD CONSTRAINT sessions_token_type_check
CHECK (
    token_type = 'Bearer'
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_sessions_profile
ON public.sessions(profile_id);

CREATE INDEX idx_sessions_device
ON public.sessions(device_id);

CREATE INDEX idx_sessions_last_activity
ON public.sessions(last_activity_at);

CREATE INDEX idx_sessions_expires
ON public.sessions(expires_at);

-- ============================================================
-- Enable RLS
-- ============================================================

ALTER TABLE public.sessions
ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Policies
-- ============================================================

CREATE POLICY "Users view own sessions"

ON public.sessions

FOR SELECT

TO authenticated

USING (

    profile_id = auth.uid()

);

CREATE POLICY "Users revoke own sessions"

ON public.sessions

FOR UPDATE

TO authenticated

USING (

    profile_id = auth.uid()

)

WITH CHECK (

    profile_id = auth.uid()

);

CREATE POLICY "System manage sessions"

ON public.sessions

FOR ALL

TO service_role

USING (true)

WITH CHECK (true);

-- ============================================================
-- Trigger
-- ============================================================

CREATE TRIGGER update_sessions_updated_at

BEFORE UPDATE

ON public.sessions

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();