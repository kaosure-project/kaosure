-- ============================================================
-- Migration : create_can_access_admin_function
-- Module    : Governance
-- Description:
-- Returns TRUE if the authenticated user is allowed
-- to access the administration system.
-- ============================================================

CREATE OR REPLACE FUNCTION public.can_access_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS
$$
BEGIN

    RETURN (
        public.is_company_owner()
        OR
        public.is_active_admin()
    );

END;
$$;

COMMENT ON FUNCTION public.can_access_admin()
IS
'Returns TRUE when the authenticated user may access the administration area.';

GRANT EXECUTE
ON FUNCTION public.can_access_admin()
TO authenticated;