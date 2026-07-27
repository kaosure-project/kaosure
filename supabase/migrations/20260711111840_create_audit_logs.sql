CREATE TABLE public.audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,

    action text NOT NULL,

    table_name text,

    record_id uuid,

    old_data jsonb,

    new_data jsonb,

    ip_address inet,

    user_agent text,

    device_info text,

    source text DEFAULT 'web',

    created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.audit_logs IS
'Stores immutable audit trail for important system actions.';