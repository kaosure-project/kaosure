CREATE TABLE public.organizations (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL,

    code text UNIQUE,

    description text,

    status text NOT NULL DEFAULT 'active',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.organizations IS
'Represents a company or organization within the KaoSure ecosystem.';