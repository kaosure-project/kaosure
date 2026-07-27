-- ============================================================
-- Migration : create_admin_sessions_rls
-- Module    : Governance
-- Table     : admin_sessions
-- ============================================================

ALTER TABLE public.admin_sessions
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY admin_sessions_select
ON public.admin_sessions
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR

    profile_id = auth.uid()

    OR

    public.has_permission('admin.sessions.view')

);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY admin_sessions_insert
ON public.admin_sessions
FOR INSERT
TO authenticated
WITH CHECK (

    FALSE

);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY admin_sessions_update
ON public.admin_sessions
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

CREATE POLICY admin_sessions_delete
ON public.admin_sessions
FOR DELETE
TO authenticated
USING (

    FALSE

);