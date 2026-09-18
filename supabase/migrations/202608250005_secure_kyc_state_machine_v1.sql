-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Secure KYC State Machine V1
-- Purpose   : Lock verification request status values
-- ============================================================

---------------------------------------------------------------
-- 1. Normalize existing NULL status
--
-- status is already NOT NULL in the original table.
-- This section is intentionally defensive for environments
-- where the schema may have been modified manually.
---------------------------------------------------------------

UPDATE public.verification_requests
SET status = 'pending'
WHERE status IS NULL;

---------------------------------------------------------------
-- 2. Validate existing status values
--
-- Before adding the constraint, fail the migration if an
-- unsupported status already exists.
---------------------------------------------------------------

DO $$
DECLARE
    invalid_statuses text;
BEGIN

    SELECT string_agg(DISTINCT status, ', ' ORDER BY status)
    INTO invalid_statuses
    FROM public.verification_requests
    WHERE status NOT IN (
        'pending',
        'under_review',
        'approved',
        'rejected',
        'cancelled'
    );

    IF invalid_statuses IS NOT NULL THEN
        RAISE EXCEPTION
            'Invalid verification request status found: %',
            invalid_statuses;
    END IF;

END;
$$;

---------------------------------------------------------------
-- 3. Lock allowed request statuses
---------------------------------------------------------------

ALTER TABLE public.verification_requests
DROP CONSTRAINT IF EXISTS chk_verification_requests_status;

ALTER TABLE public.verification_requests
ADD CONSTRAINT chk_verification_requests_status
CHECK (
    status IN (
        'pending',
        'under_review',
        'approved',
        'rejected',
        'cancelled'
    )
);

---------------------------------------------------------------
-- 4. Documentation
---------------------------------------------------------------

COMMENT ON COLUMN public.verification_requests.status
IS
'KYC request status: pending, under_review, approved, rejected, or cancelled.';

---------------------------------------------------------------
-- 5. Status index
--
-- The original migration already creates an index on status.
-- This section intentionally does not create another index.
---------------------------------------------------------------