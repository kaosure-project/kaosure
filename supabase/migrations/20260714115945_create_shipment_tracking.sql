-- ==========================================
-- Table: shipment_tracking
-- ==========================================

CREATE TABLE public.shipment_tracking (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    shipment_id uuid NOT NULL,

    tracking_status text NOT NULL,

    location text,

    description text,

    event_time timestamptz NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT shipment_tracking_shipment_id_fkey
        FOREIGN KEY (shipment_id)
        REFERENCES public.shipments(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT shipment_tracking_status_check
        CHECK (
            tracking_status IN (
                'pending',
                'picked_up',
                'processing',
                'in_transit',
                'arrived_at_hub',
                'out_for_delivery',
                'delivered',
                'returned',
                'failed'
            )
        )
);

-- ==========================================
-- COMMENT
-- ==========================================

COMMENT ON TABLE public.shipment_tracking IS
'Tracking history for shipments';

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_shipment_tracking_shipment
ON public.shipment_tracking(shipment_id);

CREATE INDEX idx_shipment_tracking_status
ON public.shipment_tracking(tracking_status);

CREATE INDEX idx_shipment_tracking_event
ON public.shipment_tracking(event_time);

-- ==========================================
-- ENABLE RLS
-- ==========================================

ALTER TABLE public.shipment_tracking
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICIES
-- ==========================================

CREATE POLICY "Users can view shipment tracking"
ON public.shipment_tracking
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.shipments s
        JOIN public.orders o
          ON o.id = s.order_id
        WHERE s.id = shipment_tracking.shipment_id
          AND (
              o.buyer_id = auth.uid()
              OR o.seller_id = auth.uid()
          )
    )
);

CREATE POLICY "Admins can manage shipment tracking"
ON public.shipment_tracking
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());