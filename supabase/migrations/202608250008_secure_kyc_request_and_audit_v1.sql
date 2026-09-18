-- ============================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Secure KYC Request and Audit V1
-- Purpose   : Harden KYC request ownership and audit integrity
-- ============================================================

---------------------------------------------------------------
-- 1. Remove direct client mutation of verification requests
---------------------------------------------------------------

DROP POLICY IF EXISTS verification_requests_update_own
ON public.verification_requests;

DROP POLICY IF EXISTS verification_requests_delete_own
ON public.verification_requests;

---------------------------------------------------------------
-- 2. Remove direct client insertion of verification logs
---------------------------------------------------------------

DROP POLICY IF EXISTS verification_logs_insert_authenticated
ON public.verification_logs;

---------------------------------------------------------------
-- 3. Rebuild verification request INSERT policy
--
-- A user may create a verification request only when:
--
-- 1. requested_by = authenticated user
-- 2. document_id belongs to the authenticated user
---------------------------------------------------------------

DROP POLICY IF EXISTS verification_requests_insert_own
ON public.verification_requests;

CREATE POLICY verification_requests_insert_own
ON public.verification_requests
FOR INSERT
TO authenticated
WITH CHECK (
    requested_by = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.identity_documents d
        WHERE d.id = document_id
          AND d.owner_id = auth.uid()
    )
);

---------------------------------------------------------------
-- 4. Documentation
---------------------------------------------------------------

COMMENT ON POLICY verification_requests_insert_own
ON public.verification_requests
IS
'Allows authenticated users to create KYC requests only for identity documents they own.';

COMMENT ON TABLE public.verification_logs
IS
'Immutable audit trail for KYC verification requests. Client-side INSERT is prohibited; trusted server-side functions are responsible for audit entries.';

COMMENT ON TABLE public.verification_requests
IS
'KYC verification requests. Users may create requests for documents they own and read their own requests. Request mutation is controlled by trusted server-side functions.';