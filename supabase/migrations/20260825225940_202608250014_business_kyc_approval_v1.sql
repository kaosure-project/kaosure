-- ============================================================
-- Kao Ecosystem / Kao ID
-- Migration 014: Business KYC Approval V1
-- Purpose: Canonical organization-level KYC approval gate
-- ============================================================

CREATE TABLE IF NOT EXISTS public.organization_verifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'not_started',
    legal_name_verified boolean NOT NULL DEFAULT false,
    registration_verified boolean NOT NULL DEFAULT false,
    authorized_person_verified boolean NOT NULL DEFAULT false,
    bank_verified boolean NOT NULL DEFAULT false,
    identity_score integer NOT NULL DEFAULT 0,
    last_verified_at timestamptz,
    last_reviewed_by uuid REFERENCES public.profiles(id),
    rejected_reason text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_organization_verification UNIQUE (organization_id),
    CONSTRAINT chk_organization_verification_status CHECK (status IN ('not_started','pending','approved','rejected','expired')),
    CONSTRAINT chk_organization_verification_score CHECK (identity_score BETWEEN 0 AND 100)
);

COMMENT ON TABLE public.organization_verifications IS
'Canonical consolidated KYC verification state for a Business Kao ID organization.';

CREATE INDEX IF NOT EXISTS idx_organization_verifications_status
ON public.organization_verifications(status);

CREATE TRIGGER trg_organization_verifications_updated_at
BEFORE UPDATE ON public.organization_verifications
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.organization_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY organization_verifications_select_member
ON public.organization_verifications
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.organization_id = organization_verifications.organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
    )
);

-- Initialize business verification state after organization registration.
CREATE OR REPLACE FUNCTION public.initialize_organization_verification(
    p_organization_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.organization_members
        WHERE organization_id = p_organization_id
          AND profile_id = auth.uid()
          AND status = 'active'
          AND role IN ('owner','director','authorized_person','admin')
    ) THEN
        RAISE EXCEPTION 'Not authorized for this organization';
    END IF;

    SELECT id INTO v_id
    FROM public.organization_verifications
    WHERE organization_id = p_organization_id;

    IF v_id IS NOT NULL THEN RETURN v_id; END IF;

    INSERT INTO public.organization_verifications (organization_id, status)
    VALUES (p_organization_id, 'pending')
    RETURNING id INTO v_id;

    RETURN v_id;
EXCEPTION WHEN unique_violation THEN
    SELECT id INTO v_id FROM public.organization_verifications WHERE organization_id = p_organization_id;
    IF v_id IS NOT NULL THEN RETURN v_id; END IF;
    RAISE;
END;
$$;

-- Approve business KYC atomically. Business Kao ID remains a separate issuance step.
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
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
    IF p_reviewer_id <> auth.uid() THEN RAISE EXCEPTION 'Reviewer identity does not match authenticated user'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'kyc_officer' AND account_status = 'active'
    ) THEN
        RAISE EXCEPTION 'KYC officer permission required';
    END IF;

    SELECT * INTO v_org FROM public.organizations WHERE id = p_organization_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Organization not found'; END IF;

    SELECT * INTO v_legal FROM public.organization_legal_profiles
    WHERE organization_id = p_organization_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Organization legal profile not found'; END IF;

    IF v_legal.registration_status <> 'active' THEN
        RAISE EXCEPTION 'Organization registration is not active';
    END IF;

    SELECT * INTO v_member FROM public.organization_members
    WHERE organization_id = p_organization_id
      AND status = 'active'
      AND role IN ('owner','director','authorized_person')
      AND EXISTS (
          SELECT 1 FROM public.kao_id_identities ki
          WHERE ki.profile_id = organization_members.profile_id
            AND ki.identity_type = 'personal'
            AND ki.status = 'active'
      )
    ORDER BY CASE role WHEN 'authorized_person' THEN 1 WHEN 'director' THEN 2 ELSE 3 END
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No verified authorized person with active Personal Kao ID found';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.bank_accounts
        WHERE organization_id = p_organization_id
          AND is_active = true
          AND is_verified = true
          AND status = 'verified'
          AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Verified active organization bank account not found';
    END IF;

    SELECT * INTO v_ver FROM public.organization_verifications
    WHERE organization_id = p_organization_id FOR UPDATE;

    IF NOT FOUND THEN
        INSERT INTO public.organization_verifications (
            organization_id,status,legal_name_verified,registration_verified,
            authorized_person_verified,bank_verified,identity_score,
            last_verified_at,last_reviewed_by
        ) VALUES (
            p_organization_id,'approved',true,true,true,true,100,
            now(),p_reviewer_id
        );
    ELSE
        UPDATE public.organization_verifications
        SET status='approved',
            legal_name_verified=true,
            registration_verified=true,
            authorized_person_verified=true,
            bank_verified=true,
            identity_score=100,
            last_verified_at=now(),
            last_reviewed_by=p_reviewer_id,
            rejected_reason=NULL,
            updated_at=now()
        WHERE organization_id=p_organization_id;
    END IF;

    UPDATE public.organization_legal_profiles
    SET verification_status='approved', verified_at=now(), verified_by=p_reviewer_id, updated_at=now()
    WHERE organization_id=p_organization_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.initialize_organization_verification(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.initialize_organization_verification(uuid) TO authenticated;
ALTER FUNCTION public.initialize_organization_verification(uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.approve_business_kyc(uuid,uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_business_kyc(uuid,uuid,text) TO authenticated;
ALTER FUNCTION public.approve_business_kyc(uuid,uuid,text) OWNER TO postgres;
;
