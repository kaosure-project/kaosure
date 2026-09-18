-- ============================================================
-- Kao Ecosystem / Kao ID
-- Migration : Register Organization V1
-- Purpose   : Atomic business-account registration
-- ============================================================

CREATE OR REPLACE FUNCTION public.register_organization(
    p_name text,
    p_legal_name text,
    p_registration_number text,
    p_organization_type text DEFAULT 'company',
    p_registration_country text DEFAULT 'TH'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_profile_id uuid;
    v_organization_id uuid;
BEGIN
    -----------------------------------------------------------
    -- 1. Authentication
    -----------------------------------------------------------
    v_profile_id := auth.uid();

    IF v_profile_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -----------------------------------------------------------
    -- 2. Validate input
    -----------------------------------------------------------
    IF NULLIF(trim(p_name), '') IS NULL THEN
        RAISE EXCEPTION 'Organization name is required';
    END IF;

    IF NULLIF(trim(p_legal_name), '') IS NULL THEN
        RAISE EXCEPTION 'Legal name is required';
    END IF;

    IF NULLIF(trim(p_registration_number), '') IS NULL THEN
        RAISE EXCEPTION 'Registration number is required';
    END IF;

    IF NULLIF(trim(p_registration_country), '') IS NULL THEN
        RAISE EXCEPTION 'Registration country is required';
    END IF;

    -----------------------------------------------------------
    -- 3. Validate authenticated profile
    -----------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = v_profile_id
          AND account_status = 'active'
    ) THEN
        RAISE EXCEPTION 'Active profile not found';
    END IF;

    -----------------------------------------------------------
    -- 4. Prevent duplicate legal registration
    -----------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM public.organization_legal_profiles
        WHERE registration_country = upper(trim(p_registration_country))
          AND registration_number = trim(p_registration_number)
    ) THEN
        RAISE EXCEPTION 'Organization registration number already exists';
    END IF;

    -----------------------------------------------------------
    -- 5. Create organization
    -----------------------------------------------------------
    INSERT INTO public.organizations (
        name,
        organization_type,
        status
    )
    VALUES (
        trim(p_name),
        trim(p_organization_type),
        'active'
    )
    RETURNING id INTO v_organization_id;

    -----------------------------------------------------------
    -- 6. Create legal identity in pending verification state
    -----------------------------------------------------------
    INSERT INTO public.organization_legal_profiles (
        organization_id,
        registration_number,
        legal_name,
        organization_type,
        registration_country,
        registration_status,
        verification_status
    )
    VALUES (
        v_organization_id,
        trim(p_registration_number),
        trim(p_legal_name),
        trim(p_organization_type),
        upper(trim(p_registration_country)),
        'active',
        'pending'
    );

    -----------------------------------------------------------
    -- 7. Register the authenticated user as authorized person
    -----------------------------------------------------------
    INSERT INTO public.organization_members (
        organization_id,
        profile_id,
        role,
        status,
        starts_at
    )
    VALUES (
        v_organization_id,
        v_profile_id,
        'authorized_person',
        'active',
        now()
    );

    -----------------------------------------------------------
    -- 8. Return organization ID
    --
    -- Business Kao ID is NOT issued here.
    -- It requires the later Business KYC approval flow.
    -----------------------------------------------------------
    RETURN v_organization_id;
END;
$$;

COMMENT ON FUNCTION public.register_organization(text, text, text, text, text)
IS
'Atomically creates an organization, its legal identity in pending verification state, and the authenticated profile as an active authorized person. Business Kao ID is issued only after Business KYC approval.';

REVOKE ALL
ON FUNCTION public.register_organization(text, text, text, text, text)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.register_organization(text, text, text, text, text)
TO authenticated;

ALTER FUNCTION public.register_organization(text, text, text, text, text)
OWNER TO postgres;
;
