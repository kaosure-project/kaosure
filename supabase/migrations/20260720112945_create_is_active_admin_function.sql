-- ============================================================
-- Migration : create_is_active_admin_function
-- Module    : Governance
-- Description:
-- Returns TRUE if the authenticated user has an active
-- admin assignment.
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_active_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN

    -- User is not authenticated
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (

        SELECT 1
        FROM public.admin_assignments aa

        WHERE aa.profile_id = v_user_id
          AND aa.is_active = TRUE
          AND aa.starts_at <= NOW()
          AND (
                aa.expires_at IS NULL
                OR aa.expires_at >= NOW()
          )

    );

END;
$$;

COMMENT ON FUNCTION public.is_active_admin()
IS 'Returns TRUE when the authenticated user has an active admin assignment.';

GRANT EXECUTE
ON FUNCTION public.is_active_admin()
TO authenticated;