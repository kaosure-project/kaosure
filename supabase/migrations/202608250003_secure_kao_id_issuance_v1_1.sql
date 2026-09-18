-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Secure Kao ID Issuance V1.1
-- Purpose   : Secure generator + KYC-gated issuance
-- ============================================================

---------------------------------------------------------------
-- 1. Secure Kao ID generator
--
-- Format:
-- K + 10 uppercase characters
-- Alphabet:
-- A-Z / 0-9
--
-- The database UNIQUE constraint remains the final authority
-- for Kao ID uniqueness.
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.generate_kao_id()
RETURNS text
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    generated_id text;
    alphabet constant text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    i integer;
BEGIN
    LOOP
        generated_id := 'K';

        FOR i IN 1..10 LOOP
            generated_id :=
                generated_id ||
                substr(
                    alphabet,
                    1 + floor(random() * length(alphabet))::integer,
                    1
                );
        END LOOP;

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
'Generates a public Kao ID candidate using K + 10 uppercase A-Z/0-9 characters. Final uniqueness is enforced by the database unique constraint.';

---------------------------------------------------------------
-- 2. Secure Kao ID issuance
--
-- Kao ID may only be issued when:
--
-- 1. Profile exists
-- 2. Profile belongs to the authenticated user
-- 3. Consolidated KYC verification exists
-- 4. KYC status is approved
--
-- The operation is idempotent:
-- an existing Kao ID is always returned.
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
    verification_status text;
BEGIN

    -----------------------------------------------------------
    -- 1. Authentication
    -----------------------------------------------------------

    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -----------------------------------------------------------
    -- 2. Profile ownership
    -----------------------------------------------------------

    IF p_profile_id <> auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to issue Kao ID for this profile';
    END IF;

    -----------------------------------------------------------
    -- 3. Validate profile
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = p_profile_id
    ) THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    -----------------------------------------------------------
    -- 4. Return existing Kao ID
    --
    -- Idempotent issuance.
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
    -- 5. KYC gate
    --
    -- The canonical consolidated verification record must
    -- exist and must be approved.
    -----------------------------------------------------------

    SELECT status
    INTO verification_status
    FROM public.verifications
    WHERE profile_id = p_profile_id
    LIMIT 1;

    IF verification_status IS NULL THEN
        RAISE EXCEPTION 'KYC verification record not found';
    END IF;

    IF verification_status <> 'approved' THEN
        RAISE EXCEPTION 'KYC verification is not approved';
    END IF;

    -----------------------------------------------------------
    -- 6. Generate Kao ID
    -----------------------------------------------------------

    new_kao_id := public.generate_kao_id();

    -----------------------------------------------------------
    -- 7. Create canonical Kao ID identity
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

    -----------------------------------------------------------
    -- 8. Return immutable public Kao ID
    -----------------------------------------------------------

    RETURN new_kao_id;

EXCEPTION
    WHEN unique_violation THEN

        -------------------------------------------------------
        -- Concurrent issuance:
        -- another transaction may have created the Kao ID
        -- for this profile first.
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
'Issues exactly one immutable Kao ID after successful KYC approval. Requires authentication and profile ownership. Idempotent for an existing Kao ID.';

---------------------------------------------------------------
-- 3. Function permissions
---------------------------------------------------------------

REVOKE ALL
ON FUNCTION public.generate_kao_id()
FROM PUBLIC;

REVOKE ALL
ON FUNCTION public.issue_kao_id(uuid)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.issue_kao_id(uuid)
TO authenticated;

---------------------------------------------------------------
-- 4. Function ownership
---------------------------------------------------------------

ALTER FUNCTION public.generate_kao_id()
OWNER TO postgres;

ALTER FUNCTION public.issue_kao_id(uuid)
OWNER TO postgres;