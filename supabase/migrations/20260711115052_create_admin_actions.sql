CREATE TABLE public.admin_actions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    admin_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    action_type text NOT NULL,

    target_table text,

    target_id uuid,

    target_profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    description text,

    old_data jsonb,

    new_data jsonb,

    ip_address inet,

    user_agent text,

    source text DEFAULT 'web',

    created_at timestamptz DEFAULT now()
);

COMMENT ON TABLE public.admin_actions IS
'Stores administrative actions performed by administrators across the KaoSure marketplace.';