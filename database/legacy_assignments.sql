CREATE OR REPLACE FUNCTION public.get_governance_admin_assignments()
 RETURNS TABLE(assignment_id uuid, kao_id text, display_name text, role_code text, role_name text, starts_at timestamp with time zone, expires_at timestamp with time zone, is_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
        ar.code::text,
        ar.name::text,
        aa.starts_at,
        aa.expires_at,
        aa.is_active
    FROM public.admin_assignments aa
    JOIN public.admin_roles ar
      ON ar.id = aa.role_id
    JOIN public.profiles p
      ON p.id = aa.profile_id
    LEFT JOIN public.kao_id_identities k
      ON k.profile_id = aa.profile_id
    ORDER BY aa.is_active DESC, ar.name, k.kao_id;
END;
$function$

