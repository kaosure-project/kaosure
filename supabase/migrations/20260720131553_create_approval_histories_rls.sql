-- ============================================================
-- Migration : create_approval_histories_rls
-- Module    : Governance
-- Table     : approval_histories
-- ============================================================

ALTER TABLE public.approval_histories
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY approval_histories_select
ON public.approval_histories
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    actor_profile_id = auth.uid()

    OR

    EXISTS (

        SELECT 1
        FROM public.approval_requests r
        WHERE r.id = approval_histories.approval_request_id
        AND r.requested_by = auth.uid()

    )

    OR

    EXISTS (

        SELECT 1
        FROM public.approval_steps s
        WHERE s.id = approval_histories.approval_step_id
        AND s.approver_profile_id = auth.uid()

    )

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY approval_histories_insert
ON public.approval_histories
FOR INSERT
TO authenticated
WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY approval_histories_update
ON public.approval_histories
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

CREATE POLICY approval_histories_delete
ON public.approval_histories
FOR DELETE
TO authenticated
USING (

    FALSE

);