-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Initialize Verification V1
-- Purpose   : Create canonical verification state for a profile
-- ============================================================

---------------------------------------------------------------
-- 1. Initialize verification
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.initialize_verification(
    p_profile_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_verification_id uuid;
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
        RAISE EXCEPTION
            'Not authorized to initialize verification for this profile';
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
    -- 4. Return existing verification
    --
    -- Idempotent:
    -- Multiple calls must never create multiple verification
    -- records for the same profile.
    -----------------------------------------------------------

    SELECT id
    INTO v_verification_id
    FROM public.verifications
    WHERE profile_id = p_profile_id
    LIMIT 1;

    IF v_verification_id IS NOT NULL THEN
        RETURN v_verification_id;
    END IF;

    -----------------------------------------------------------
    -- 5. Create canonical verification state
    -----------------------------------------------------------

    INSERT INTO public.verifications (
        profile_id,
        account_level,
        status,
        email_verified,
        phone_verified,
        identity_card_status,
        passport_status,
        residence_permit_status,
        bank_status,
        identity_score,
        created_at,
        updated_at
    )
    VALUES (
        p_profile_id,
        'registered',
        'not_started',
        false,
        false,
        'not_started',
        'not_started',
        'not_started',
        'not_started',
        0,
        now(),
        now()
    )
    RETURNING id
    INTO v_verification_id;

    -----------------------------------------------------------
    -- 6. Return verification ID
    -----------------------------------------------------------

    RETURN v_verification_id;

EXCEPTION
    WHEN unique_violation THEN

        -------------------------------------------------------
        -- Concurrent initialization:
        -- another transaction created the verification first.
        -------------------------------------------------------

        SELECT id
        INTO v_verification_id
        FROM public.verifications
        WHERE profile_id = p_profile_id
        LIMIT 1;

        IF v_verification_id IS NOT NULL THEN
            RETURN v_verification_id;
        END IF;

        RAISE;
END;
$$;

---------------------------------------------------------------
-- 2. Documentation
---------------------------------------------------------------

COMMENT ON FUNCTION public.initialize_verification(uuid)
IS
'Creates the canonical verification state for an authenticated profile. Idempotent and concurrency-safe.';

---------------------------------------------------------------
-- 3. Function permissions
---------------------------------------------------------------

REVOKE ALL
ON FUNCTION public.initialize_verification(uuid)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.initialize_verification(uuid)
TO authenticated;

---------------------------------------------------------------
-- 4. Function ownership
---------------------------------------------------------------

ALTER FUNCTION public.initialize_verification(uuid)
OWNER TO postgres;