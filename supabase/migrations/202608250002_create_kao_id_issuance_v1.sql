-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Create Kao ID Issuance V1
-- Purpose   : Secure and concurrency-safe Kao ID issuance
-- ============================================================

---------------------------------------------------------------
-- 1. Kao ID generator
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.generate_kao_id()
RETURNS text
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    generated_id text;
BEGIN
    LOOP
        generated_id :=
            'K' ||
            upper(
                substr(
                    encode(gen_random_bytes(8), 'hex'),
                    1,
                    10
                )
            );

        EXIT WHEN NOT EXISTS (
            SELECT 1
            FROM public.kao_id_identities
            WHERE kao_id = generated_id
        );
    END LOOP;

    RETURN generated_id;
END;
$$;

COMMENT ON FUNCTION public.generate_kao_id()
IS
'Generates a random public Kao ID candidate. Final uniqueness is enforced by the unique constraint on kao_id.';

---------------------------------------------------------------
-- 2. Issue Kao ID
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.issue_kao_id(
    p_profile_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    existing_kao_id text;
    new_kao_id text;
BEGIN

    -----------------------------------------------------------
    -- Validate profile
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = p_profile_id
    ) THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    -----------------------------------------------------------
    -- Return existing Kao ID
    --
    -- Idempotent:
    -- Calling this function multiple times does not create
    -- multiple Kao IDs for the same profile.
    -----------------------------------------------------------

    SELECT kao_id
    INTO existing_kao_id
    FROM public.kao_id_identities
    WHERE profile_id = p_profile_id
    LIMIT 1;

    IF existing_kao_id IS NOT NULL THEN
        RETURN existing_kao_id;
    END IF;

    -----------------------------------------------------------
    -- Generate new Kao ID
    -----------------------------------------------------------

    new_kao_id := public.generate_kao_id();

    -----------------------------------------------------------
    -- Create canonical Kao ID identity
    -----------------------------------------------------------

    INSERT INTO public.kao_id_identities (
        profile_id,
        kao_id,
        status,
        issued_at
    )
    VALUES (
        p_profile_id,
        new_kao_id,
        'active',
        now()
    );

    RETURN new_kao_id;

EXCEPTION
    WHEN unique_violation THEN

        -------------------------------------------------------
        -- Another concurrent request may have issued the
        -- Kao ID first.
        --
        -- Re-read the canonical identity and return it.
        -------------------------------------------------------

        SELECT kao_id
        INTO existing_kao_id
        FROM public.kao_id_identities
        WHERE profile_id = p_profile_id
        LIMIT 1;

        IF existing_kao_id IS NOT NULL THEN
            RETURN existing_kao_id;
        END IF;

        RAISE;
END;
$$;

COMMENT ON FUNCTION public.issue_kao_id(uuid)
IS
'Issues one immutable Kao ID for a profile. Idempotent and safe against concurrent issuance attempts.';

---------------------------------------------------------------
-- 3. Restrict direct execution
---------------------------------------------------------------

REVOKE ALL
ON FUNCTION public.generate_kao_id()
FROM PUBLIC;

REVOKE ALL
ON FUNCTION public.issue_kao_id(uuid)
FROM PUBLIC;

---------------------------------------------------------------
-- 4. Allow authenticated users to request their own issuance
--
-- IMPORTANT:
-- The function itself must verify KYC eligibility before
-- production use.
---------------------------------------------------------------

GRANT EXECUTE
ON FUNCTION public.issue_kao_id(uuid)
TO authenticated;

---------------------------------------------------------------
-- 5. Security
---------------------------------------------------------------

ALTER FUNCTION public.issue_kao_id(uuid)
OWNER TO postgres;

ALTER FUNCTION public.generate_kao_id()
OWNER TO postgres;