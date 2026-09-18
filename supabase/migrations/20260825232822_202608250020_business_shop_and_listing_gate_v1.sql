-- Kao Ecosystem / Marketplace
-- Business shops + unified Personal/Business seller listing gate.

ALTER TABLE public.shops
ADD COLUMN IF NOT EXISTS organization_id uuid
    REFERENCES public.organizations(id)
    ON DELETE CASCADE;

ALTER TABLE public.shops
ADD COLUMN IF NOT EXISTS seller_identity_type text NOT NULL DEFAULT 'personal';

ALTER TABLE public.shops
DROP CONSTRAINT IF EXISTS chk_shops_seller_identity_type;

ALTER TABLE public.shops
ADD CONSTRAINT chk_shops_seller_identity_type
CHECK (seller_identity_type IN ('personal','business'));

ALTER TABLE public.shops
DROP CONSTRAINT IF EXISTS chk_shops_seller_identity_owner;

ALTER TABLE public.shops
ADD CONSTRAINT chk_shops_seller_identity_owner
CHECK (
    (seller_identity_type = 'personal' AND organization_id IS NULL)
    OR
    (seller_identity_type = 'business' AND organization_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_shops_organization_id
ON public.shops(organization_id);

CREATE INDEX IF NOT EXISTS idx_shops_seller_identity_type
ON public.shops(seller_identity_type);

COMMENT ON COLUMN public.shops.seller_identity_type
IS 'Seller identity used by this shop: personal or business.';

COMMENT ON COLUMN public.shops.organization_id
IS 'Business organization owning this shop when seller_identity_type is business.';

CREATE OR REPLACE FUNCTION public.create_business_shop(
    p_organization_id uuid,
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
        WHERE k.organization_id = p_organization_id
          AND k.profile_id IS NULL
          AND k.identity_type = 'business'
          AND k.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Active Business Kao ID is required';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.organization_members om
        WHERE om.organization_id = p_organization_id
          AND om.profile_id = auth.uid()
          AND om.status = 'active'
          AND om.role IN ('owner','admin','director','authorized_person')
    ) THEN
        RAISE EXCEPTION 'Authorized organization member required';
    END IF;

    IF NOT public.is_identity_financially_verified(
        'business', NULL, p_organization_id
    ) THEN
        RAISE EXCEPTION 'Business financial verification is required';
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
        p_organization_id,
        'business',
        p_shop_name,
        p_shop_slug,
        p_description
    )
    RETURNING id INTO v_shop_id;

    RETURN v_shop_id;
END;
$$;

COMMENT ON FUNCTION public.create_business_shop(uuid,text,text,text)
IS 'Creates a Business Marketplace shop for an active Business Kao ID owner/member after business financial verification.';

REVOKE ALL ON FUNCTION public.create_business_shop(uuid,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_business_shop(uuid,text,text,text) TO authenticated;
ALTER FUNCTION public.create_business_shop(uuid,text,text,text) OWNER TO postgres;

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

    SELECT owner_id, seller_identity_type, organization_id
    INTO v_owner_id, v_identity_type, v_organization_id
    FROM public.shops
    WHERE id = p_shop_id
      AND shop_status = 'active';

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Shop not found or inactive';
    END IF;

    IF v_identity_type = 'personal' THEN
        IF v_owner_id <> auth.uid() THEN
            RAISE EXCEPTION 'Not authorized to create products for this shop';
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM public.kao_id_identities k
            WHERE k.profile_id = auth.uid()
              AND k.organization_id IS NULL
              AND k.identity_type = 'personal'
              AND k.status = 'active'
        ) THEN
            RAISE EXCEPTION 'Active Personal Kao ID is required before listing products';
        END IF;

        IF NOT public.is_identity_financially_verified('personal', auth.uid(), NULL) THEN
            RAISE EXCEPTION 'Personal financial verification is required before listing products';
        END IF;

    ELSIF v_identity_type = 'business' THEN
        IF v_organization_id IS NULL THEN
            RAISE EXCEPTION 'Business shop organization is missing';
        END IF;

        IF v_owner_id <> auth.uid() THEN
            IF NOT EXISTS (
                SELECT 1
                FROM public.organization_members om
                WHERE om.organization_id = v_organization_id
                  AND om.profile_id = auth.uid()
                  AND om.status = 'active'
                  AND om.role IN ('owner','admin','director','authorized_person')
            ) THEN
                RAISE EXCEPTION 'Not authorized to create products for this business shop';
            END IF;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM public.kao_id_identities k
            WHERE k.organization_id = v_organization_id
              AND k.profile_id IS NULL
              AND k.identity_type = 'business'
              AND k.status = 'active'
        ) THEN
            RAISE EXCEPTION 'Active Business Kao ID is required before listing products';
        END IF;

        IF NOT public.is_identity_financially_verified('business', NULL, v_organization_id) THEN
            RAISE EXCEPTION 'Business financial verification is required before listing products';
        END IF;
    ELSE
        RAISE EXCEPTION 'Unsupported seller identity type';
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
        shop_id, category_id, title, slug, description,
        condition_level, price, stock, status, is_active
    )
    VALUES (
        p_shop_id, p_category_id, p_title, p_slug, p_description,
        p_condition_level, p_price, p_stock, 'draft', true
    )
    RETURNING id INTO v_product_id;

    RETURN v_product_id;
END;
$$;

COMMENT ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer)
IS 'Creates a marketplace product only for an authorized active Personal or Business Kao ID seller with required financial verification.';

REVOKE ALL ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) TO authenticated;
ALTER FUNCTION public.create_marketplace_product(uuid,uuid,text,text,text,smallint,numeric,integer) OWNER TO postgres;
;
