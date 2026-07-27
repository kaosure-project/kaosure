-- ==========================================
-- Table: shipments
-- ==========================================

CREATE TABLE public.shipments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    platform_id uuid NOT NULL,
    order_id uuid NOT NULL,
    shipping_method_id uuid,

    tracking_number text,
    carrier text,

    shipping_status text NOT NULL DEFAULT 'pending',

    shipped_at timestamptz,
    delivered_at timestamptz,
    estimated_delivery timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- Foreign Keys
    CONSTRAINT shipments_platform_id_fkey
        FOREIGN KEY (platform_id)
        REFERENCES public.platforms(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT shipments_order_id_fkey
        FOREIGN KEY (order_id)
        REFERENCES public.orders(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT shipments_shipping_method_id_fkey
        FOREIGN KEY (shipping_method_id)
        REFERENCES public.shipping_methods(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    -- Check Constraint
    CONSTRAINT shipments_status_check
        CHECK (
            shipping_status IN (
                'pending',
                'preparing',
                'shipped',
                'in_transit',
                'delivered',
                'returned',
                'cancelled'
            )
        )
);

-- ==========================================
-- COMMENT
-- ==========================================

COMMENT ON TABLE public.shipments IS
'Shipment information for KaoSure orders';

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_shipments_platform
ON public.shipments(platform_id);

CREATE INDEX idx_shipments_order
ON public.shipments(order_id);

CREATE INDEX idx_shipments_tracking
ON public.shipments(tracking_number);

CREATE INDEX idx_shipments_status
ON public.shipments(shipping_status);

-- ==========================================
-- TRIGGER
-- ==========================================

CREATE TRIGGER update_shipments_updated_at
BEFORE UPDATE
ON public.shipments
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- ENABLE RLS
-- ==========================================

ALTER TABLE public.shipments
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICIES
-- ==========================================

CREATE POLICY "Users can view own shipments"
ON public.shipments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.orders
        WHERE orders.id = shipments.order_id
          AND (
              orders.buyer_id = auth.uid()
              OR orders.seller_id = auth.uid()
          )
    )
);

CREATE POLICY "Admins can manage shipments"
ON public.shipments
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());