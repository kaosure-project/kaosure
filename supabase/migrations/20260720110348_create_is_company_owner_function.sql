-- ============================================================
-- Migration : create_is_company_owner_function
-- Module    : Governance
-- Description:
-- Returns TRUE when the current authenticated user is
-- the company owner or an active delegated owner.
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_company_owner()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();

    -- Not authenticated
    IF v_user_id IS NULL THEN
        RETURN FALSE;
    END IF;

    ------------------------------------------------------------------
    -- Direct Company Owner
    ------------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM public.company_owners
        WHERE profile_id = v_user_id
    ) THEN
        RETURN TRUE;
    END IF;

    ------------------------------------------------------------------
    -- Active Owner Delegation
    ------------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM public.owner_delegations
        WHERE delegate_profile_id = v_user_id
          AND revoked_at IS NULL
          AND starts_at <= NOW()
          AND (
                expires_at IS NULL
                OR expires_at >= NOW()
              )
    ) THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION public.is_company_owner() IS
'Returns TRUE if the authenticated user is the company owner or has an active owner delegation.';

GRANT EXECUTE ON FUNCTION public.is_company_owner()
TO authenticated;