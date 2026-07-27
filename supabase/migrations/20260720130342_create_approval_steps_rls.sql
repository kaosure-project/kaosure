-- ============================================================
-- Migration : create_approval_steps_rls
-- Module    : Governance
-- Table     : approval_steps
-- ============================================================

ALTER TABLE public.approval_steps
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY approval_steps_select
ON public.approval_steps
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    approver_profile_id = auth.uid()

    OR

    approved_by = auth.uid()

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY approval_steps_insert
ON public.approval_steps
FOR INSERT
TO authenticated
WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY approval_steps_update
ON public.approval_steps
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

CREATE POLICY approval_steps_delete
ON public.approval_steps
FOR DELETE
TO authenticated
USING (

    FALSE

);