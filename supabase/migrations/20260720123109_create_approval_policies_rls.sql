-- ============================================================
-- Migration : create_approval_policies_rls
-- Module    : Governance
-- Table     : approval_policies
-- ============================================================

ALTER TABLE public.approval_policies
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY approval_policies_select
ON public.approval_policies
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    public.has_permission('approval.policy.view')

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY approval_policies_insert
ON public.approval_policies
FOR INSERT
TO authenticated
WITH CHECK (

    public.is_company_owner()

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY approval_policies_update
ON public.approval_policies
FOR UPDATE
TO authenticated
USING (

    public.is_company_owner()

)

WITH CHECK (

    public.is_company_owner()

);

---------------------------------------------------------------
-- DELETE
---------------------------------------------------------------

CREATE POLICY approval_policies_delete
ON public.approval_policies
FOR DELETE
TO authenticated
USING (

    FALSE

);