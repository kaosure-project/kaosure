-- Kao Ecosystem / Kao ID
-- Financial verification is a seller-eligibility layer, not an identity/Kao ID gate.

CREATE OR REPLACE FUNCTION public.is_identity_financially_verified(
    p_identity_type text,
    p_profile_id uuid DEFAULT NULL,
    p_organization_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_identity_type NOT IN ('personal','business') THEN
        RETURN false;
    END IF;

    IF p_identity_type = 'personal' THEN
        IF p_profile_id IS NULL OR p_organization_id IS NOT NULL THEN
            RETURN false;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM public.kao_id_identities k
            WHERE k.profile_id = p_profile_id
              AND k.organization_id IS NULL
              AND k.identity_type = 'personal'
              AND k.status = 'active'
        ) THEN
            RETURN false;
        END IF;

        RETURN EXISTS (
            SELECT 1
            FROM public.financial_verifications fv
            JOIN public.bank_accounts ba
              ON ba.id = fv.bank_account_id
            WHERE fv.identity_type = 'personal'
              AND fv.profile_id = p_profile_id
              AND fv.organization_id IS NULL
              AND fv.status = 'approved'
              AND fv.name_match_status = 'matched'
              AND ba.profile_id = p_profile_id
              AND ba.organization_id IS NULL
              AND ba.is_verified = true
              AND ba.is_active = true
              AND ba.deleted_at IS NULL
              AND ba.status = 'verified'
        );
    END IF;

    IF p_organization_id IS NULL OR p_profile_id IS NOT NULL THEN
        RETURN false;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.kao_id_identities k
        WHERE k.organization_id = p_organization_id
          AND k.profile_id IS NULL
          AND k.identity_type = 'business'
          AND k.status = 'active'
    ) THEN
        RETURN false;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.financial_verifications fv
        JOIN public.bank_accounts ba
          ON ba.id = fv.bank_account_id
        WHERE fv.identity_type = 'business'
          AND fv.organization_id = p_organization_id
          AND fv.profile_id IS NULL
          AND fv.status = 'approved'
          AND fv.name_match_status = 'matched'
          AND ba.organization_id = p_organization_id
          AND ba.profile_id IS NULL
          AND ba.is_verified = true
          AND ba.is_active = true
          AND ba.deleted_at IS NULL
          AND ba.status = 'verified'
    );
END;
$$;

COMMENT ON FUNCTION public.is_identity_financially_verified(text,uuid,uuid)
IS 'Checks seller financial eligibility for a Personal or Business Kao ID. Financial verification is separate from identity issuance and is required for seller eligibility.';

REVOKE ALL ON FUNCTION public.is_identity_financially_verified(text,uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_identity_financially_verified(text,uuid,uuid) TO authenticated;
ALTER FUNCTION public.is_identity_financially_verified(text,uuid,uuid) OWNER TO postgres;
;
