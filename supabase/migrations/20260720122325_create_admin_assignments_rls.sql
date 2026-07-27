-- ============================================================
-- Migration : create_admin_assignments_rls
-- Module    : Governance
-- Table     : admin_assignments
-- ============================================================

ALTER TABLE public.admin_assignments
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY admin_assignments_select
ON public.admin_assignments
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    profile_id = auth.uid()

    OR

    public.has_permission('admin.assignments.view')

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY admin_assignments_insert
ON public.admin_assignments
FOR INSERT
TO authenticated
WITH CHECK (

    public.is_company_owner()

    OR

    public.has_permission('admin.assignments.create')

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY admin_assignments_update
ON public.admin_assignments
FOR UPDATE
TO authenticated
USING (

    public.is_company_owner()

    OR

    public.has_permission('admin.assignments.update')

)

WITH CHECK (

    public.is_company_owner()

    OR

    public.has_permission('admin.assignments.update')

);

---------------------------------------------------------------
-- DELETE
---------------------------------------------------------------

CREATE POLICY admin_assignments_delete
ON public.admin_assignments
FOR DELETE
TO authenticated
USING (

    FALSE

);