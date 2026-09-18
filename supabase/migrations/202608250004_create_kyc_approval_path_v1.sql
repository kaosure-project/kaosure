-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : KYC Approval Path V1
-- Purpose   : Atomic and secure KYC approval
-- ============================================================

---------------------------------------------------------------
-- 1. Approve KYC verification request
--
-- Canonical flow:
--
-- verification_requests
--        ↓
-- verification_logs
--        ↓
-- verifications
--        ↓
-- KYC approved
--
-- Kao ID issuance is handled separately by issue_kao_id().
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.approve_kyc_verification(
    p_verification_request_id uuid,
    p_reviewer_id uuid,
    p_notes text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_request public.verification_requests%ROWTYPE;
BEGIN

    -----------------------------------------------------------
    -- 1. Authentication
    -----------------------------------------------------------

    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -----------------------------------------------------------
    -- 2. Reviewer identity
    -----------------------------------------------------------

    IF p_reviewer_id <> auth.uid() THEN
        RAISE EXCEPTION
            'Reviewer identity does not match authenticated user';
    END IF;

    -----------------------------------------------------------
    -- 3. Reviewer permission
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = auth.uid()
          AND role = 'kyc_officer'
          AND account_status = 'active'
    ) THEN
        RAISE EXCEPTION 'KYC officer permission required';
    END IF;

    -----------------------------------------------------------
    -- 4. Lock verification request
    --
    -- Prevent concurrent approval attempts.
    -----------------------------------------------------------

    SELECT *
    INTO v_request
    FROM public.verification_requests
    WHERE id = p_verification_request_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Verification request not found';
    END IF;

    -----------------------------------------------------------
    -- 5. Validate request state
    --
    -- Only pending / under_review requests can be approved.
    -----------------------------------------------------------

    IF v_request.status NOT IN (
        'pending',
        'under_review'
    ) THEN
        RAISE EXCEPTION
            'Verification request cannot be approved from status: %',
            v_request.status;
    END IF;

    -----------------------------------------------------------
    -- 6. Verify consolidated KYC record exists
    --
    -- verifications is the canonical KYC state for the profile.
    -- It must already exist before approval.
    -----------------------------------------------------------

    IF NOT EXISTS (
        SELECT 1
        FROM public.verifications
        WHERE profile_id = v_request.requested_by
    ) THEN
        RAISE EXCEPTION
            'Verification record not found for profile';
    END IF;

    -----------------------------------------------------------
    -- 7. Lock consolidated verification record
    -----------------------------------------------------------

    PERFORM 1
    FROM public.verifications
    WHERE profile_id = v_request.requested_by
    FOR UPDATE;

    -----------------------------------------------------------
    -- 8. Update consolidated KYC state
    -----------------------------------------------------------

    UPDATE public.verifications
    SET
        account_level = 'verified',
        status = 'approved',
        last_verified_at = now(),
        last_reviewed_by = p_reviewer_id,
        rejected_reason = NULL,
        updated_at = now()
    WHERE profile_id = v_request.requested_by;

    -----------------------------------------------------------
    -- 9. Update verification request
    -----------------------------------------------------------

    UPDATE public.verification_requests
    SET
        status = 'approved',
        reviewed_at = now(),
        reviewed_by = p_reviewer_id,
        rejection_reason = NULL,
        notes = COALESCE(p_notes, notes),
        updated_at = now()
    WHERE id = p_verification_request_id;

    -----------------------------------------------------------
    -- 10. Write audit log
    -----------------------------------------------------------

    INSERT INTO public.verification_logs (
        verification_request_id,
        action,
        old_status,
        new_status,
        performed_by,
        notes,
        created_at
    )
    VALUES (
        p_verification_request_id,
        'approve',
        v_request.status,
        'approved',
        p_reviewer_id,
        p_notes,
        now()
    );

    -----------------------------------------------------------
    -- 11. Success
    -----------------------------------------------------------

    RETURN true;

END;
$$;

COMMENT ON FUNCTION public.approve_kyc_verification(
    uuid,
    uuid,
    text
)
IS
'Atomically approves a KYC verification request, updates the canonical consolidated verification state, updates the request status, and records an audit log. Requires an authenticated active KYC officer.';

---------------------------------------------------------------
-- 12. Function security
---------------------------------------------------------------

REVOKE ALL
ON FUNCTION public.approve_kyc_verification(
    uuid,
    uuid,
    text
)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.approve_kyc_verification(
    uuid,
    uuid,
    text
)
TO authenticated;

ALTER FUNCTION public.approve_kyc_verification(
    uuid,
    uuid,
    text
)
OWNER TO postgres;