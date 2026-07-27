-- ==========================================
-- TABLE: shipping_methods
-- ==========================================

CREATE TABLE public.shipping_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    platform_id uuid NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    description text,

    carrier text,
    service_type text,

    min_weight numeric(10,2),
    max_weight numeric(10,2),

    estimated_days integer,

    is_active boolean NOT NULL DEFAULT true,
    sort_order integer NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT shipping_methods_code_unique UNIQUE(platform_id, code),

    CONSTRAINT shipping_methods_platform_id_fkey
        FOREIGN KEY(platform_id)
        REFERENCES public.platforms(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT shipping_methods_sort_order_check
        CHECK(sort_order >= 0)
);

COMMENT ON TABLE public.shipping_methods IS
'Shipping methods for each KaoSure platform';

COMMENT ON COLUMN public.shipping_methods.platform_id IS
'Reference to KaoSure platform';

CREATE INDEX idx_shipping_methods_platform
ON public.shipping_methods(platform_id);

CREATE INDEX idx_shipping_methods_active
ON public.shipping_methods(is_active);

CREATE INDEX idx_shipping_methods_sort
ON public.shipping_methods(sort_order);

CREATE TRIGGER update_shipping_methods_updated_at
BEFORE UPDATE ON public.shipping_methods
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE public.shipping_methods
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read shipping methods"
ON public.shipping_methods
FOR SELECT
TO authenticated
USING (is_active = true);

CREATE POLICY "Admins can manage shipping methods"
ON public.shipping_methods
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());