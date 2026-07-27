-- ============================================================
-- Migration : create_role_permissions_rls
-- Module    : Governance
-- Table     : role_permissions
-- ============================================================

ALTER TABLE public.role_permissions
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY role_permissions_select
ON public.role_permissions
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    public.has_permission('admin.roles.view')

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY role_permissions_insert
ON public.role_permissions
FOR INSERT
TO authenticated
WITH CHECK (

    public.is_company_owner()

    OR

    public.has_permission('admin.roles.update')

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY role_permissions_update
ON public.role_permissions
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

CREATE POLICY role_permissions_delete
ON public.role_permissions
FOR DELETE
TO authenticated
USING (

    public.is_company_owner()

    OR

    public.has_permission('admin.roles.update')

);