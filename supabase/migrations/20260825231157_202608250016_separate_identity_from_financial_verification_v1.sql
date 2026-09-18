-- Kao Ecosystem / Kao ID
-- Separate identity issuance from financial/seller verification.
-- Bank account verification is NOT required to create a Kao ID.
-- It is a later financial/seller eligibility gate.

CREATE OR REPLACE FUNCTION public.approve_business_kyc(
    p_organization_id uuid,
    p_reviewer_id uuid,
    p_notes text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org public.organizations%ROWTYPE;
    v_legal public.organization_legal_profiles%ROWTYPE;
    v_ver public.organization_verifications%ROWTYPE;
    v_member public.organization_members%ROWTYPE;
    v_bank_verified boolean := false;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF p_reviewer_id <> auth.uid() THEN
        RAISE EXCEPTION 'Reviewer identity does not match authenticated user';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'kyc_officer'
          AND account_status = 'active'
    ) THEN
        RAISE EXCEPTION 'KYC officer permission required';
    END IF;

    SELECT * INTO v_org
    FROM public.organizations
    WHERE id = p_organization_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organization not found';
    END IF;

    SELECT * INTO v_legal
    FROM public.organization_legal_profiles
    WHERE organization_id = p_organization_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Organization legal profile not found';
    END IF;

    IF v_legal.registration_status <> 'active' THEN
        RAISE EXCEPTION 'Organization registration is not active';
    END IF;

    SELECT * INTO v_member
    FROM public.organization_members om
    WHERE om.organization_id = p_organization_id
      AND om.status = 'active'
      AND om.role IN ('owner','director','authorized_person')
      AND EXISTS (
          SELECT 1
          FROM public.kao_id_identities ki
          WHERE ki.profile_id = om.profile_id
            AND ki.identity_type = 'personal'
            AND ki.organization_id IS NULL
            AND ki.status = 'active'
      )
    ORDER BY CASE om.role
        WHEN 'authorized_person' THEN 1
        WHEN 'director' THEN 2
        ELSE 3
    END
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No verified authorized person with active Personal Kao ID found';
    END IF;

    -- Bank verification is recorded when available, but is NOT an identity gate.
    SELECT EXISTS (
        SELECT 1
        FROM public.bank_accounts
        WHERE organization_id = p_organization_id
          AND is_active = true
          AND is_verified = true
          AND status = 'verified'
          AND deleted_at IS NULL
    ) INTO v_bank_verified;

    SELECT * INTO v_ver
    FROM public.organization_verifications
    WHERE organization_id = p_organization_id
    FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.organization_verifications (
            organization_id,
            status,
            legal_name_verified,
            registration_verified,
            authorized_person_verified,
            bank_verified,
            identity_score,
            last_verified_at,
            last_reviewed_by
        ) VALUES (
            p_organization_id,
            'approved',
            true,
            true,
            true,
            v_bank_verified,
            100,
            now(),
            p_reviewer_id
        );
    ELSE
        UPDATE public.organization_verifications
        SET status = 'approved',
            legal_name_verified = true,
            registration_verified = true,
            authorized_person_verified = true,
            bank_verified = v_bank_verified,
            identity_score = 100,
            last_verified_at = now(),
            last_reviewed_by = p_reviewer_id,
            rejected_reason = NULL,
            updated_at = now()
        WHERE organization_id = p_organization_id;
    END IF;

    UPDATE public.organization_legal_profiles
    SET verification_status = 'approved',
        verified_at = now(),
        verified_by = p_reviewer_id,
        updated_at = now()
    WHERE organization_id = p_organization_id;

    RETURN true;
END;
$$;

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
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.organizations
        WHERE id = p_organization_id
    ) THEN
        RAISE EXCEPTION 'Organization not found';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = p_organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
          AND om.role IN ('owner','admin','director','authorized_person')
    ) THEN
        RAISE EXCEPTION 'Authorized organization member required';
    END IF;

    SELECT kao_id INTO v_existing_kao_id
    FROM public.kao_id_identities
    WHERE organization_id = p_organization_id
      AND identity_type = 'business'
    LIMIT 1;

    IF v_existing_kao_id IS NOT NULL THEN
        RETURN v_existing_kao_id;
    END IF;

    -- Business identity gate: approved Business KYC only.
    -- Financial/bank verification is intentionally NOT required here.
    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_verifications ov
        WHERE ov.organization_id = p_organization_id
          AND ov.status = 'approved'
    ) THEN
        RAISE EXCEPTION 'Business KYC is not approved';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_legal_profiles olp
        WHERE olp.organization_id = p_organization_id
          AND olp.verification_status = 'approved'
          AND olp.registration_status = 'active'
    ) THEN
        RAISE EXCEPTION 'Organization legal verification is not approved';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_members om
        JOIN public.kao_id_identities ki
          ON ki.profile_id = om.profile_id
         AND ki.identity_type = 'personal'
         AND ki.organization_id IS NULL
         AND ki.status = 'active'
        WHERE om.organization_id = p_organization_id
          AND om.status = 'active'
          AND om.role IN ('owner','director','authorized_person')
    ) THEN
        RAISE EXCEPTION 'Verified authorized person with Personal Kao ID is required';
    END IF;

    v_new_kao_id := public.generate_kao_id();

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
        SELECT kao_id INTO v_existing_kao_id
        FROM public.kao_id_identities
        WHERE organization_id = p_organization_id
          AND identity_type = 'business'
        LIMIT 1;

        IF v_existing_kao_id IS NOT NULL THEN
            RETURN v_existing_kao_id;
        END IF;
        RAISE;
END;
$$;

COMMENT ON FUNCTION public.approve_business_kyc(uuid,uuid,text)
IS 'Approves Business KYC based on legal identity and verified authorized person identity. Bank verification is recorded when available but is not required for Kao ID issuance.';

COMMENT ON FUNCTION public.issue_business_kao_id(uuid)
IS 'Issues Business Kao ID after approved Business KYC and verified authorized-person identity. Corporate bank verification is a separate financial/seller eligibility gate.';

REVOKE ALL ON FUNCTION public.approve_business_kyc(uuid,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_business_kyc(uuid,uuid,text) TO authenticated;
ALTER FUNCTION public.approve_business_kyc(uuid,uuid,text) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.issue_business_kao_id(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.issue_business_kao_id(uuid) TO authenticated;
ALTER FUNCTION public.issue_business_kao_id(uuid) OWNER TO postgres;
;
