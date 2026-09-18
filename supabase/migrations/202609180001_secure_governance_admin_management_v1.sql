-- ============================================================
-- Kao Ecosystem
-- Kao ID Governance
-- Migration : Secure Governance Admin Management V1
-- Purpose   : Kao ID based governance assignment and audit
-- ============================================================

---------------------------------------------------------------
-- 1. Canonical built-in governance roles
---------------------------------------------------------------

INSERT INTO public.admin_roles (
    name,
    code,
    description,
    is_system,
    is_active
)
VALUES
    (
        'Super Admin',
        'super_admin',
        'High-privilege administrator for Kao Ecosystem governance.',
        true,
        true
    ),
    (
        'Admin',
        'admin',
        'General administrator role.',
        true,
        true
    ),
    (
        'KYC Officer',
        'kyc_officer',
        'Reviews identity verification and KYC requests.',
        true,
        true
    ),
    (
        'Support',
        'support',
        'Customer and member support role.',
        true,
        true
    )
ON CONFLICT (code)
DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_system = true,
    is_active = true,
    updated_at = now();

---------------------------------------------------------------
-- 2. Harden Company Owner identity
--
-- Owner is not a special Kao ID.
-- Owner authority is an authorization assignment attached to
-- a normal verified and active Kao ID profile.
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_company_owner()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RETURN false;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles p
        JOIN public.verifications v
          ON v.profile_id = p.id
         AND v.status = 'approved'
        JOIN public.kao_id_identities k
          ON k.profile_id = p.id
         AND k.status = 'active'
        WHERE p.id = v_user_id
          AND p.account_status = 'active'
    ) THEN
        RETURN false;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.company_owners co
        WHERE co.profile_id = v_user_id
    ) THEN
        RETURN true;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.owner_delegations od
        WHERE od.delegate_profile_id = v_user_id
          AND od.revoked_at IS NULL
          AND od.starts_at <= now()
          AND od.expires_at >= now()
    );
END;
$$;

REVOKE ALL
ON FUNCTION public.is_company_owner()
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.is_company_owner()
TO authenticated;

ALTER FUNCTION public.is_company_owner()
OWNER TO postgres;

---------------------------------------------------------------
-- 3. Governance access summary
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_governance_access()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_is_owner boolean;
    v_is_admin boolean;
    v_roles jsonb;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    v_is_owner := public.is_company_owner();
    v_is_admin := public.is_active_admin();

    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'code', ar.code,
                'name', ar.name
            )
            ORDER BY ar.name
        ),
        '[]'::jsonb
    )
    INTO v_roles
    FROM public.admin_assignments aa
    JOIN public.admin_roles ar
      ON ar.id = aa.role_id
    WHERE aa.profile_id = v_user_id
      AND aa.is_active = true
      AND aa.starts_at <= now()
      AND (
          aa.expires_at IS NULL
          OR aa.expires_at >= now()
      )
      AND ar.is_active = true;

    RETURN jsonb_build_object(
        'is_owner', v_is_owner,
        'is_admin', v_is_admin,
        'can_access_admin', (v_is_owner OR v_is_admin),
        'roles', v_roles
    );
END;
$$;

REVOKE ALL
ON FUNCTION public.get_governance_access()
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.get_governance_access()
TO authenticated;

ALTER FUNCTION public.get_governance_access()
OWNER TO postgres;

---------------------------------------------------------------
-- 4. Governance assignment listing
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_governance_admin_assignments()
RETURNS TABLE (
    assignment_id uuid,
    kao_id text,
    display_name text,
    role_code text,
    role_name text,
    starts_at timestamptz,
    expires_at timestamptz,
    is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT (
        public.is_company_owner()
        OR public.has_permission('admin.assignments.view')
    ) THEN
        RAISE EXCEPTION 'Governance assignment view permission required';
    END IF;

    RETURN QUERY
    SELECT
        aa.id,
        k.kao_id,
        COALESCE(
            NULLIF(p.display_name, ''),
            NULLIF(concat_ws(' ', p.first_name, p.last_name), ''),
            k.kao_id
        ),
        ar.code,
        ar.name,
        aa.starts_at,
        aa.expires_at,
        aa.is_active
    FROM public.admin_assignments aa
    JOIN public.admin_roles ar
      ON ar.id = aa.role_id
    JOIN public.profiles p
      ON p.id = aa.profile_id
    JOIN public.kao_id_identities k
      ON k.profile_id = aa.profile_id
    ORDER BY aa.is_active DESC, ar.name, k.kao_id;
END;
$$;

REVOKE ALL
ON FUNCTION public.get_governance_admin_assignments()
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.get_governance_admin_assignments()
TO authenticated;

ALTER FUNCTION public.get_governance_admin_assignments()
OWNER TO postgres;

---------------------------------------------------------------
-- 5. Assign administrator role by Kao ID
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.assign_admin_role(
    p_target_kao_id text,
    p_role_code text,
    p_expires_at timestamptz DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_id uuid := auth.uid();
    v_target_profile_id uuid;
    v_role_id uuid;
    v_assignment_id uuid;
BEGIN
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT (
        public.is_company_owner()
        OR public.has_permission('admin.assignments.create')
    ) THEN
        RAISE EXCEPTION 'Admin assignment permission required';
    END IF;

    IF p_expires_at IS NOT NULL
       AND p_expires_at <= now() THEN
        RAISE EXCEPTION 'Assignment expiration must be in the future';
    END IF;

    SELECT k.profile_id
    INTO v_target_profile_id
    FROM public.kao_id_identities k
    JOIN public.profiles p
      ON p.id = k.profile_id
    JOIN public.verifications v
      ON v.profile_id = k.profile_id
    WHERE k.kao_id = upper(trim(p_target_kao_id))
      AND k.status = 'active'
      AND p.account_status = 'active'
      AND v.status = 'approved'
    LIMIT 1;

    IF v_target_profile_id IS NULL THEN
        RAISE EXCEPTION
            'Target Kao ID is not active and KYC approved';
    END IF;

    SELECT ar.id
    INTO v_role_id
    FROM public.admin_roles ar
    WHERE ar.code = lower(trim(p_role_code))
      AND ar.is_active = true
    LIMIT 1;

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Governance role not found or inactive';
    END IF;

    INSERT INTO public.admin_assignments (
        profile_id,
        role_id,
        assigned_by,
        starts_at,
        expires_at,
        is_active
    )
    VALUES (
        v_target_profile_id,
        v_role_id,
        v_actor_id,
        now(),
        p_expires_at,
        true
    )
    ON CONFLICT (profile_id, role_id)
    DO UPDATE SET
        assigned_by = EXCLUDED.assigned_by,
        starts_at = now(),
        expires_at = EXCLUDED.expires_at,
        is_active = true,
        updated_at = now()
    RETURNING id
    INTO v_assignment_id;

    INSERT INTO public.admin_actions (
        admin_id,
        action_type,
        target_table,
        target_id,
        target_profile_id,
        description,
        new_data,
        source
    )
    VALUES (
        v_actor_id,
        'governance.role.assign',
        'admin_assignments',
        v_assignment_id,
        v_target_profile_id,
        'Assigned governance role by Kao ID',
        jsonb_build_object(
            'kao_id', upper(trim(p_target_kao_id)),
            'role_code', lower(trim(p_role_code)),
            'expires_at', p_expires_at
        ),
        'governance_rpc'
    );

    RETURN v_assignment_id;
END;
$$;

REVOKE ALL
ON FUNCTION public.assign_admin_role(text, text, timestamptz)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.assign_admin_role(text, text, timestamptz)
TO authenticated;

ALTER FUNCTION public.assign_admin_role(text, text, timestamptz)
OWNER TO postgres;

---------------------------------------------------------------
-- 6. Revoke administrator assignment
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.revoke_admin_assignment(
    p_assignment_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_id uuid := auth.uid();
    v_assignment public.admin_assignments%ROWTYPE;
BEGIN
    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT (
        public.is_company_owner()
        OR public.has_permission('admin.assignments.update')
    ) THEN
        RAISE EXCEPTION 'Admin assignment update permission required';
    END IF;

    SELECT *
    INTO v_assignment
    FROM public.admin_assignments
    WHERE id = p_assignment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Admin assignment not found';
    END IF;

    UPDATE public.admin_assignments
    SET
        is_active = false,
        updated_at = now()
    WHERE id = p_assignment_id;

    INSERT INTO public.admin_actions (
        admin_id,
        action_type,
        target_table,
        target_id,
        target_profile_id,
        description,
        old_data,
        new_data,
        source
    )
    VALUES (
        v_actor_id,
        'governance.role.revoke',
        'admin_assignments',
        p_assignment_id,
        v_assignment.profile_id,
        'Revoked governance role assignment',
        jsonb_build_object(
            'is_active', v_assignment.is_active,
            'role_id', v_assignment.role_id
        ),
        jsonb_build_object(
            'is_active', false,
            'role_id', v_assignment.role_id
        ),
        'governance_rpc'
    );

    RETURN true;
END;
$$;

REVOKE ALL
ON FUNCTION public.revoke_admin_assignment(uuid)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.revoke_admin_assignment(uuid)
TO authenticated;

ALTER FUNCTION public.revoke_admin_assignment(uuid)
OWNER TO postgres;

---------------------------------------------------------------
-- 7. Block direct client mutation of admin assignments
--
-- Reads remain governed by the existing SELECT policy.
-- Mutations must use trusted RPC functions above.
---------------------------------------------------------------

DROP POLICY IF EXISTS admin_assignments_insert
ON public.admin_assignments;

DROP POLICY IF EXISTS admin_assignments_update
ON public.admin_assignments;

DROP POLICY IF EXISTS admin_assignments_delete
ON public.admin_assignments;

COMMENT ON TABLE public.admin_assignments
IS
'Governance role assignments. Client applications may read according to RLS; assignment and revocation mutations are performed through trusted audited RPC functions.';
