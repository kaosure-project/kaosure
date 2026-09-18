-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Business Kao ID Issuance V1
-- Purpose   : Secure Business Kao ID issuance
-- ============================================================

CREATE OR REPLACE FUNCTION public.issue_business_kao_id(
    p_organization_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_kao_id text;
    v_new_kao_id text;
BEGIN

    -----------------------------------------------------------
    -- 1. Authentication
    -----------------------------------------------------------

    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -----------------------------------------------------------
    -- 2. Organization must exist
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.organizations
        WHERE id = p_organization_id
    ) THEN
        RAISE EXCEPTION 'Organization not found';
    END IF;

    -----------------------------------------------------------
    -- 3. Caller must be an active authorized organization member
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = p_organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
          AND om.role IN (
              'owner',
              'admin',
              'director',
              'authorized_person'
          )
    ) THEN
        RAISE EXCEPTION 'Authorized organization member required';
    END IF;

    -----------------------------------------------------------
    -- 4. Return existing Business Kao ID
    -----------------------------------------------------------

    SELECT kao_id
    INTO v_existing_kao_id
    FROM public.kao_id_identities
    WHERE organization_id = p_organization_id
    LIMIT 1;

    IF v_existing_kao_id IS NOT NULL THEN
        RETURN v_existing_kao_id;
    END IF;

    -----------------------------------------------------------
    -- 5. Legal entity verification gate
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_legal_profiles olp
        WHERE olp.organization_id = p_organization_id
          AND olp.verification_status = 'approved'
          AND olp.registration_status = 'active'
    ) THEN
        RAISE EXCEPTION 'Organization legal verification is not approved';
    END IF;

    -----------------------------------------------------------
    -- 6. Authorized person must have a Personal Kao ID
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_members om
        JOIN public.kao_id_identities ki
          ON ki.profile_id = om.profile_id
         AND ki.organization_id IS NULL
         AND ki.status = 'active'
        WHERE om.organization_id = p_organization_id
          AND om.status = 'active'
          AND om.role IN ('owner', 'director', 'authorized_person')
    ) THEN
        RAISE EXCEPTION 'Verified authorized person with Personal Kao ID is required';
    END IF;

    -----------------------------------------------------------
    -- 7. Verified corporate bank account gate
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.bank_accounts ba
        WHERE ba.organization_id = p_organization_id
          AND ba.is_verified = true
          AND ba.is_active = true
          AND ba.deleted_at IS NULL
          AND ba.status = 'verified'
    ) THEN
        RAISE EXCEPTION 'Verified corporate bank account is required';
    END IF;

    -----------------------------------------------------------
    -- 8. Generate canonical Kao ID
    -----------------------------------------------------------

    v_new_kao_id := public.generate_kao_id();

    -----------------------------------------------------------
    -- 9. Create Business Identity
    -----------------------------------------------------------

    INSERT INTO public.kao_id_identities (
        profile_id,
        organization_id,
        identity_type,
        kao_id,
        status,
        issued_at
    )
    VALUES (
        NULL,
        p_organization_id,
        'business',
        v_new_kao_id,
        'active',
        now()
    );

    RETURN v_new_kao_id;

EXCEPTION
    WHEN unique_violation THEN

        SELECT kao_id
        INTO v_existing_kao_id
        FROM public.kao_id_identities
        WHERE organization_id = p_organization_id
        LIMIT 1;

        IF v_existing_kao_id IS NOT NULL THEN
            RETURN v_existing_kao_id;
        END IF;

        RAISE;
END;
$$;

COMMENT ON FUNCTION public.issue_business_kao_id(uuid)
IS
'Issues exactly one Business Kao ID after approved legal entity verification, an active authorized person with Personal Kao ID, and a verified active corporate bank account.';

REVOKE ALL
ON FUNCTION public.issue_business_kao_id(uuid)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.issue_business_kao_id(uuid)
TO authenticated;

ALTER FUNCTION public.issue_business_kao_id(uuid)
OWNER TO postgres;
;
