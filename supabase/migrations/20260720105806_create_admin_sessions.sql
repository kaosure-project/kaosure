-- ============================================================
-- Migration : create_admin_sessions
-- Module    : Governance
-- Table     : admin_sessions
-- Description:
-- Tracks administrator sessions for security monitoring and auditing.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.admin_sessions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id UUID NOT NULL,

    session_id UUID NOT NULL,

    ip_address INET,

    user_agent TEXT,

    device_name VARCHAR(255),

    platform VARCHAR(100),

    login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    logout_at TIMESTAMPTZ,

    terminated_at TIMESTAMPTZ,

    terminated_by UUID,

    termination_reason TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_admin_sessions_session_id
        UNIQUE (session_id),

    CONSTRAINT fk_admin_sessions_profile
        FOREIGN KEY (profile_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_admin_sessions_terminated_by
        FOREIGN KEY (terminated_by)
        REFERENCES public.profiles(id)
        ON DELETE SET NULL

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_admin_sessions_profile
ON public.admin_sessions(profile_id);

CREATE INDEX idx_admin_sessions_is_active
ON public.admin_sessions(is_active);

CREATE INDEX idx_admin_sessions_login_at
ON public.admin_sessions(login_at);

CREATE INDEX idx_admin_sessions_last_activity
ON public.admin_sessions(last_activity_at);

CREATE INDEX idx_admin_sessions_ip
ON public.admin_sessions(ip_address);

CREATE INDEX idx_admin_sessions_session
ON public.admin_sessions(session_id);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.admin_sessions IS
'Tracks administrator sessions for security monitoring and auditing.';

COMMENT ON COLUMN public.admin_sessions.profile_id IS
'Administrator profile owning the session.';

COMMENT ON COLUMN public.admin_sessions.session_id IS
'Unique authentication session identifier.';

COMMENT ON COLUMN public.admin_sessions.ip_address IS
'Client IP address.';

COMMENT ON COLUMN public.admin_sessions.user_agent IS
'Client user agent string.';

COMMENT ON COLUMN public.admin_sessions.device_name IS
'Friendly device name.';

COMMENT ON COLUMN public.admin_sessions.platform IS
'Client platform or operating system.';

COMMENT ON COLUMN public.admin_sessions.login_at IS
'Timestamp when the administrator logged in.';

COMMENT ON COLUMN public.admin_sessions.last_activity_at IS
'Last recorded administrator activity.';

COMMENT ON COLUMN public.admin_sessions.logout_at IS
'Timestamp when the administrator logged out normally.';

COMMENT ON COLUMN public.admin_sessions.terminated_at IS
'Timestamp when the session was forcefully terminated.';

COMMENT ON COLUMN public.admin_sessions.terminated_by IS
'Administrator who forcefully terminated the session.';

COMMENT ON COLUMN public.admin_sessions.termination_reason IS
'Reason for forced termination.';

COMMENT ON COLUMN public.admin_sessions.is_active IS
'Whether the session is currently active.';

COMMENT ON COLUMN public.admin_sessions.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.admin_sessions.updated_at IS
'Record last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.admin_sessions
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the Governance RBAC
-- infrastructure is fully implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_admin_sessions_updated_at
BEFORE UPDATE
ON public.admin_sessions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();