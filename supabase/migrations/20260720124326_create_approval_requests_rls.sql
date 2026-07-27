-- ============================================================
-- Migration : create_approval_requests_rls
-- Module    : Governance
-- Table     : approval_requests
-- ============================================================

ALTER TABLE public.approval_requests
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY approval_requests_select
ON public.approval_requests
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    requested_by = auth.uid()

    OR

    EXISTS (

        SELECT 1
        FROM public.approval_steps s
        WHERE s.approval_request_id = approval_requests.id
        AND s.approver_profile_id = auth.uid()

    )

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY approval_requests_insert
ON public.approval_requests
FOR INSERT
TO authenticated
WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY approval_requests_update
ON public.approval_requests
FOR UPDATE
TO authenticated
USING (

    FALSE

)

WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- DELETE
---------------------------------------------------------------

CREATE POLICY approval_requests_delete
ON public.approval_requests
FOR DELETE
TO authenticated
USING (

    FALSE

);