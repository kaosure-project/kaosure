-- ============================================================
-- Migration : create_owner_delegations_rls
-- Module    : Governance
-- Table     : owner_delegations
-- ============================================================

ALTER TABLE public.owner_delegations
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY owner_delegations_select
ON public.owner_delegations
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    delegate_profile_id = auth.uid()

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY owner_delegations_insert
ON public.owner_delegations
FOR INSERT
TO authenticated
WITH CHECK (

    public.is_company_owner()

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY owner_delegations_update
ON public.owner_delegations
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

CREATE POLICY owner_delegations_delete
ON public.owner_delegations
FOR DELETE
TO authenticated
USING (

    FALSE

);