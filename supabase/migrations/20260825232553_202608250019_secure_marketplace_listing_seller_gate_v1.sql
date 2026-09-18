-- Kao Ecosystem / KaoSure Marketplace
-- Server-side seller eligibility gate for product listing creation.

CREATE OR REPLACE FUNCTION public.create_marketplace_product(
    p_shop_id uuid,
    p_category_id uuid,
    p_title text,
    p_slug text,
    p_description text,
    p_condition_level smallint,
    p_price numeric,
    p_stock integer DEFAULT 1
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_product_id uuid;
    v_owner_id uuid;
    v_identity_type text;
    v_organization_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT owner_id
    INTO v_owner_id
    FROM public.shops
    WHERE id = p_shop_id
      AND shop_status = 'active';

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Shop not found or inactive';
    END IF;

    IF v_owner_id <> auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to create products for this shop';
    END IF;

    -- A shop owner must have an active Personal Kao ID.
    IF EXISTS (
        SELECT 1
        FROM public.kao_id_identities k
        WHERE k.profile_id = auth.uid()
          AND k.organization_id IS NULL
          AND k.identity_type = 'personal'
          AND k.status = 'active'
    ) THEN
        v_identity_type := 'personal';
    ELSE
        RAISE EXCEPTION 'Active Personal Kao ID is required before listing products';
    END IF;

    -- Seller financial verification is the Marketplace gate.
    IF NOT public.is_identity_financially_verified(
        v_identity_type,
        auth.uid(),
        NULL
    ) THEN
        RAISE EXCEPTION 'Financial verification is required before listing products';
    END IF;

    IF p_title IS NULL OR btrim(p_title) = '' THEN
        RAISE EXCEPTION 'Product title is required';
    END IF;

    IF p_price IS NULL OR p_price <= 0 THEN
        RAISE EXCEPTION 'Product price must be greater than zero';
    END IF;

    IF p_stock IS NULL OR p_stock < 1 THEN
        RAISE EXCEPTION 'Product stock must be at least 1';
    END IF;

    INSERT INTO public.products (
        shop_id,
        category_id,
        title,
        slug,
        description,
        condition_level,
        price,
        stock,
        status,
        is_active
    )
    VALUES (
        p_shop_id,
        p_category_id,
        p_title,
        p_slug,
        p_description,
        p_condition_level,
        p_price,
        p_stock,
        'draft',
        true
    )
    RETURNING id INTO v_product_id;

    RETURN v_product_id;
END;
$$;

COMMENT ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer)
IS 'Creates a Marketplace product only for an authenticated shop owner with an active Personal Kao ID and approved financial verification.';

REVOKE ALL ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) TO authenticated;
ALTER FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) OWNER TO postgres;

-- Remove the previous direct client INSERT path so Flutter cannot bypass the seller gate.
DROP POLICY IF EXISTS "Users can create products" ON public.products;
;
