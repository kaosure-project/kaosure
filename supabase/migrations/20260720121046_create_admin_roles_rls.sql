ALTER TABLE public.admin_roles
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------
-- SELECT
---------------------------------------------------------

CREATE POLICY admin_roles_select
ON public.admin_roles
FOR SELECT
TO authenticated
USING (

    public.has_permission('admin.roles.view')

);

---------------------------------------------------------
-- INSERT
---------------------------------------------------------

CREATE POLICY admin_roles_insert
ON public.admin_roles
FOR INSERT
TO authenticated
WITH CHECK (

    public.has_permission('admin.roles.create')

);

---------------------------------------------------------
-- UPDATE
---------------------------------------------------------

CREATE POLICY admin_roles_update
ON public.admin_roles
FOR UPDATE
TO authenticated
USING (

    public.has_permission('admin.roles.update')

)

WITH CHECK (

    public.has_permission('admin.roles.update')

);

---------------------------------------------------------
-- DELETE
---------------------------------------------------------

CREATE POLICY admin_roles_delete
ON public.admin_roles
FOR DELETE
TO authenticated
USING (

    public.has_permission('admin.roles.delete')

);