-- ============================================================
-- Migration : create_permissions_rls
-- Module    : Governance
-- Table     : permissions
-- ============================================================

ALTER TABLE public.permissions
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY permissions_select
ON public.permissions
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    public.has_permission('admin.permissions.view')

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY permissions_insert
ON public.permissions
FOR INSERT
TO authenticated
WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY permissions_update
ON public.permissions
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

CREATE POLICY permissions_delete
ON public.permissions
FOR DELETE
TO authenticated
USING (

    FALSE

);