-- REVIEW ONLY: no production migration has been applied.
-- Match the existing KYC officer role in admin_roles/admin_assignments.
-- Preserve the existing approval updates and audit log.
-- Validate in a development branch before deployment.
BEGIN;
SET LOCAL lock_timeout = '5s';
CREATE OR REPLACE FUNCTION public.approve_kyc_verification(p_verification_request_id uuid, p_reviewer_id uuid, p_notes text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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

    IF p_reviewer_id IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION
            'Reviewer identity does not match authenticated user';
    END IF;

    -----------------------------------------------------------
    -- 3. Reviewer permission
    -----------------------------------------------------------

    IF NOT public.is_active_admin() OR NOT EXISTS (
        SELECT 1
        FROM public.admin_assignments aa
        JOIN public.admin_roles ar ON ar.id = aa.role_id
        WHERE aa.profile_id = auth.uid()
          AND aa.is_active = true
          AND aa.starts_at <= now()
          AND (aa.expires_at IS NULL OR aa.expires_at >= now())
          AND ar.is_active = true
          AND ar.code = 'kyc_officer'
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
$function$;

-- Inspect installed definition within this transaction, then undo.
SELECT pg_get_functiondef('public.approve_kyc_verification(uuid,uuid,text)'::regprocedure);
ROLLBACK;
