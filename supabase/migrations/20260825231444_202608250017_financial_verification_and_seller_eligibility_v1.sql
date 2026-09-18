-- ============================================================
-- Kao Ecosystem / Kao ID
-- Migration 017: Financial Verification + Seller Eligibility V1
-- ============================================================

CREATE TABLE IF NOT EXISTS public.financial_verifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id uuid NOT NULL REFERENCES public.bank_accounts(id) ON DELETE CASCADE,
    identity_type text NOT NULL DEFAULT 'personal',
    profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
    organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE,
    name_match_status text NOT NULL DEFAULT 'pending',
    status text NOT NULL DEFAULT 'pending',
    verified_at timestamptz,
    verified_by uuid REFERENCES public.profiles(id),
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_financial_verification_identity_type CHECK (identity_type IN ('personal','business')),
    CONSTRAINT chk_financial_verification_name_match CHECK (name_match_status IN ('pending','matched','mismatched')),
    CONSTRAINT chk_financial_verification_status CHECK (status IN ('pending','approved','rejected','expired')),
    CONSTRAINT chk_financial_verification_owner CHECK (
        (identity_type = 'personal' AND profile_id IS NOT NULL AND organization_id IS NULL)
        OR
        (identity_type = 'business' AND organization_id IS NOT NULL AND profile_id IS NULL)
    ),
    CONSTRAINT uq_financial_verification_bank_account UNIQUE (bank_account_id)
);

CREATE INDEX IF NOT EXISTS idx_financial_verifications_profile
ON public.financial_verifications(profile_id);

CREATE INDEX IF NOT EXISTS idx_financial_verifications_organization
ON public.financial_verifications(organization_id);

CREATE INDEX IF NOT EXISTS idx_financial_verifications_status
ON public.financial_verifications(status);

ALTER TABLE public.financial_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY financial_verifications_select_own
ON public.financial_verifications
FOR SELECT TO authenticated
USING (
    profile_id = auth.uid()
    OR EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = financial_verifications.organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
    )
);

DROP TRIGGER IF EXISTS trg_financial_verifications_updated_at
ON public.financial_verifications;

CREATE TRIGGER trg_financial_verifications_updated_at
BEFORE UPDATE ON public.financial_verifications
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.financial_verifications IS
'Financial verification layer. It validates bank-account ownership/name matching for financial operations and seller eligibility; it does not issue or define Kao ID.';

-- Reviewer-controlled verification. This intentionally does not issue Kao ID.
CREATE OR REPLACE FUNCTION public.approve_financial_verification(
    p_bank_account_id uuid,
    p_reviewer_id uuid,
    p_name_match_status text,
    p_notes text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_bank public.bank_accounts%ROWTYPE;
    v_identity_type text;
    v_profile_id uuid;
    v_organization_id uuid;
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

    IF p_name_match_status NOT IN ('matched','mismatched') THEN
        RAISE EXCEPTION 'Invalid name match status';
    END IF;

    SELECT * INTO v_bank
    FROM public.bank_accounts
    WHERE id = p_bank_account_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bank account not found';
    END IF;

    IF v_bank.deleted_at IS NOT NULL OR NOT v_bank.is_active THEN
        RAISE EXCEPTION 'Bank account is inactive or deleted';
    END IF;

    IF v_bank.organization_id IS NOT NULL THEN
        v_identity_type := 'business';
        v_organization_id := v_bank.organization_id;
        v_profile_id := NULL;
    ELSE
        v_identity_type := 'personal';
        v_profile_id := v_bank.profile_id;
        v_organization_id := NULL;
    END IF;

    INSERT INTO public.financial_verifications (
        bank_account_id, identity_type, profile_id, organization_id,
        name_match_status, status, verified_at, verified_by, notes
    )
    VALUES (
        p_bank_account_id, v_identity_type, v_profile_id, v_organization_id,
        p_name_match_status,
        CASE WHEN p_name_match_status = 'matched' THEN 'approved' ELSE 'rejected' END,
        now(), p_reviewer_id, p_notes
    )
    ON CONFLICT (bank_account_id) DO UPDATE SET
        name_match_status = EXCLUDED.name_match_status,
        status = EXCLUDED.status,
        verified_at = EXCLUDED.verified_at,
        verified_by = EXCLUDED.verified_by,
        notes = EXCLUDED.notes,
        updated_at = now();

    UPDATE public.bank_accounts
    SET is_verified = (p_name_match_status = 'matched'),
        status = CASE WHEN p_name_match_status = 'matched' THEN 'verified' ELSE 'rejected' END,
        verified_at = CASE WHEN p_name_match_status = 'matched' THEN now() ELSE NULL END,
        verified_by = p_reviewer_id,
        updated_at = now()
    WHERE id = p_bank_account_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.approve_financial_verification(uuid,uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_financial_verification(uuid,uuid,text,text) TO authenticated;
ALTER FUNCTION public.approve_financial_verification(uuid,uuid,text,text) OWNER TO postgres;

-- Seller eligibility is deliberately separate from Kao ID issuance.
CREATE OR REPLACE FUNCTION public.is_seller_financially_verified(
    p_profile_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.kao_id_identities ki
        JOIN public.financial_verifications fv
          ON fv.profile_id = ki.profile_id
         AND fv.identity_type = 'personal'
         AND fv.status = 'approved'
         AND fv.name_match_status = 'matched'
        JOIN public.bank_accounts ba
          ON ba.id = fv.bank_account_id
         AND ba.is_active = true
         AND ba.is_verified = true
         AND ba.deleted_at IS NULL
        WHERE ki.profile_id = p_profile_id
          AND ki.identity_type = 'personal'
          AND ki.status = 'active'
    );
$$;

REVOKE ALL ON FUNCTION public.is_seller_financially_verified(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_seller_financially_verified(uuid) TO authenticated;
ALTER FUNCTION public.is_seller_financially_verified(uuid) OWNER TO postgres;

COMMENT ON FUNCTION public.is_seller_financially_verified(uuid) IS
'Returns whether a person with an active Personal Kao ID has an approved financial verification with a matched bank-account name. Separate from Kao ID issuance.';
;
