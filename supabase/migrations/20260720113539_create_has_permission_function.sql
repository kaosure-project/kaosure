-- ============================================================
-- Migration : create_has_permission_function
-- Module    : Governance
-- Description:
-- Central RBAC permission checker.
--
-- Permission Flow
--
-- auth.uid()
--      │
--      ▼
-- is_company_owner()
--      │
--      ├── TRUE  -> Full Access
--      │
--      ▼
-- is_active_admin()
--      │
--      ├── FALSE -> Deny
--      │
--      ▼
-- admin_assignments
--      │
--      ▼
-- role_permissions
--      │
--      ▼
-- permissions
--      │
--      ▼
-- permission.code
--
-- Example:
--
-- public.has_permission('admin.users.view')
-- public.has_permission('orders.refund')
--
-- ============================================================

CREATE OR REPLACE FUNCTION public.has_permission(
    p_permission_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS
$$
DECLARE
    v_user_id UUID;
BEGIN

    ------------------------------------------------------------
    -- Authentication Required
    ------------------------------------------------------------

    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    ------------------------------------------------------------
    -- Company Owner
    -- Full access
    ------------------------------------------------------------

    IF public.is_company_owner() THEN
        RETURN TRUE;
    END IF;

    ------------------------------------------------------------
    -- Must be Active Admin
    ------------------------------------------------------------

    IF NOT public.is_active_admin() THEN
        RETURN FALSE;
    END IF;

    ------------------------------------------------------------
    -- Permission Check
    ------------------------------------------------------------

    RETURN EXISTS (

        SELECT 1

        FROM public.admin_assignments aa

        INNER JOIN public.admin_roles ar
            ON ar.id = aa.role_id

        INNER JOIN public.role_permissions rp
            ON rp.role_id = ar.id

        INNER JOIN public.permissions p
            ON p.id = rp.permission_id

        WHERE aa.profile_id = v_user_id

          AND aa.is_active = TRUE

          AND (
                aa.starts_at IS NULL
                OR aa.starts_at <= NOW()
          )

          AND (
                aa.expires_at IS NULL
                OR aa.expires_at >= NOW()
          )

          AND ar.is_active = TRUE

          AND p.is_active = TRUE

          AND p.code = p_permission_code

    );

END;
$$;

COMMENT ON FUNCTION public.has_permission(TEXT)
IS
'Returns TRUE when the authenticated user owns the specified permission code. Company Owner always has full access.';

GRANT EXECUTE
ON FUNCTION public.has_permission(TEXT)
TO authenticated;