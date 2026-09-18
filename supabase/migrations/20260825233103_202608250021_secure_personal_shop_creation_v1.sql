-- Kao Ecosystem / Marketplace
-- Personal Shop creation must pass Kao ID + financial eligibility.

CREATE OR REPLACE FUNCTION public.create_personal_shop(
    p_shop_name text,
    p_shop_slug text,
    p_description text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shop_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.kao_id_identities k
        WHERE k.profile_id = auth.uid()
          AND k.organization_id IS NULL
          AND k.identity_type = 'personal'
          AND k.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Active Personal Kao ID is required';
    END IF;

    IF NOT public.is_identity_financially_verified(
        'personal', auth.uid(), NULL
    ) THEN
        RAISE EXCEPTION 'Personal financial verification is required';
    END IF;

    IF p_shop_name IS NULL OR btrim(p_shop_name) = '' THEN
        RAISE EXCEPTION 'Shop name is required';
    END IF;

    IF p_shop_slug IS NULL OR btrim(p_shop_slug) = '' THEN
        RAISE EXCEPTION 'Shop slug is required';
    END IF;

    INSERT INTO public.shops (
        owner_id,
        organization_id,
        seller_identity_type,
        shop_name,
        shop_slug,
        description
    )
    VALUES (
        auth.uid(),
        NULL,
        'personal',
        p_shop_name,
        p_shop_slug,
        p_description
    )
    RETURNING id INTO v_shop_id;

    RETURN v_shop_id;
END;
$$;

COMMENT ON FUNCTION public.create_personal_shop(text,text,text)
IS 'Creates a Personal Marketplace Shop only for an authenticated user with an active Personal Kao ID and approved financial verification.';

REVOKE ALL ON FUNCTION public.create_personal_shop(text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_personal_shop(text,text,text) TO authenticated;
ALTER FUNCTION public.create_personal_shop(text,text,text) OWNER TO postgres;

DROP POLICY IF EXISTS "Users can create own shop" ON public.shops;
;
