-- ==========================================
-- Table: shipping_rates
-- ==========================================

CREATE TABLE public.shipping_rates (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    platform_id uuid NOT NULL,

    shipping_method_id uuid NOT NULL,

    province text,

    min_weight numeric NOT NULL DEFAULT 0,
    max_weight numeric NOT NULL,

    price numeric(10,2) NOT NULL,

    estimated_days integer,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT shipping_rates_platform_id_fkey
        FOREIGN KEY (platform_id)
        REFERENCES public.platforms(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT shipping_rates_shipping_method_id_fkey
        FOREIGN KEY (shipping_method_id)
        REFERENCES public.shipping_methods(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT shipping_rates_weight_check
        CHECK (
            min_weight >= 0
            AND max_weight > min_weight
        ),

    CONSTRAINT shipping_rates_price_check
        CHECK (price >= 0)
);

-- ==========================================
-- COMMENT
-- ==========================================

COMMENT ON TABLE public.shipping_rates IS
'Shipping price table';

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_shipping_rates_platform
ON public.shipping_rates(platform_id);

CREATE INDEX idx_shipping_rates_method
ON public.shipping_rates(shipping_method_id);

CREATE INDEX idx_shipping_rates_province
ON public.shipping_rates(province);

CREATE INDEX idx_shipping_rates_active
ON public.shipping_rates(is_active);

-- ==========================================
-- TRIGGER
-- ==========================================

CREATE TRIGGER update_shipping_rates_updated_at
BEFORE UPDATE
ON public.shipping_rates
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- ENABLE RLS
-- ==========================================

ALTER TABLE public.shipping_rates
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICIES
-- ==========================================

CREATE POLICY "Everyone can view shipping rates"
ON public.shipping_rates
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can manage shipping rates"
ON public.shipping_rates
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());