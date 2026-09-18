-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Create Kao ID Identity V1
-- Purpose   : Canonical public identity of the Kao Ecosystem
-- ============================================================

---------------------------------------------------------------
-- 1. Kao ID Identity
---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.kao_id_identities (

    id uuid PRIMARY KEY
        DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    kao_id text NOT NULL,

    status text NOT NULL
        DEFAULT 'active',

    issued_at timestamptz NOT NULL,

    created_at timestamptz NOT NULL
        DEFAULT now(),

    updated_at timestamptz NOT NULL
        DEFAULT now(),

    -----------------------------------------------------------
    -- One Kao ID per Profile
    -----------------------------------------------------------

    CONSTRAINT uq_kao_id_identity_profile
        UNIQUE (profile_id),

    -----------------------------------------------------------
    -- One Profile per Kao ID
    -----------------------------------------------------------

    CONSTRAINT uq_kao_id_identity_kao_id
        UNIQUE (kao_id),

    -----------------------------------------------------------
    -- Kao ID public format
    --
    -- K + 10 characters
    -- Uppercase A-Z / 0-9
    -----------------------------------------------------------

    CONSTRAINT chk_kao_id_identity_format
        CHECK (
            kao_id ~ '^K[A-Z0-9]{10}$'
        ),

    -----------------------------------------------------------
    -- Identity status
    -----------------------------------------------------------

    CONSTRAINT chk_kao_id_identity_status
        CHECK (
            status IN (
                'active',
                'suspended',
                'closed'
            )
        )

);

---------------------------------------------------------------
-- 2. Comments
---------------------------------------------------------------

COMMENT ON TABLE public.kao_id_identities
IS
'Canonical public Kao ID identity for the Kao Ecosystem.';

COMMENT ON COLUMN public.kao_id_identities.id
IS
'Internal UUID of the Kao ID identity record.';

COMMENT ON COLUMN public.kao_id_identities.profile_id
IS
'Profile that owns this Kao ID. One profile can have only one Kao ID.';

COMMENT ON COLUMN public.kao_id_identities.kao_id
IS
'Public immutable Kao ID. Format: K + 10 uppercase alphanumeric characters.';

COMMENT ON COLUMN public.kao_id_identities.status
IS
'Kao ID identity status: active, suspended, or closed.';

COMMENT ON COLUMN public.kao_id_identities.issued_at
IS
'Timestamp when the Kao ID was officially issued.';

---------------------------------------------------------------
-- 3. Indexes
---------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_kao_id_identity_profile
ON public.kao_id_identities(profile_id);

CREATE INDEX IF NOT EXISTS idx_kao_id_identity_status
ON public.kao_id_identities(status);

---------------------------------------------------------------
-- 4. Updated At Trigger
---------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_kao_id_identity_updated_at
ON public.kao_id_identities;

CREATE TRIGGER trg_kao_id_identity_updated_at

BEFORE UPDATE

ON public.kao_id_identities

FOR EACH ROW

EXECUTE FUNCTION public.set_updated_at();

---------------------------------------------------------------
-- 5. Row Level Security
---------------------------------------------------------------

ALTER TABLE public.kao_id_identities
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- 6. Owner Policy
---------------------------------------------------------------

CREATE POLICY kao_id_identity_select_own

ON public.kao_id_identities

FOR SELECT

USING (
    profile_id = auth.uid()
);
