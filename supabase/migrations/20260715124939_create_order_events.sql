-- ==========================================
-- Table: order_events
-- ==========================================

CREATE TABLE public.order_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    event_type text NOT NULL,

    description text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT order_events_event_type_check
        CHECK (
            event_type IN (
                'created',
                'paid',
                'processing',
                'shipped',
                'delivered',
                'completed',
                'cancel_requested',
                'cancelled',
                'refund_requested',
                'refunded',
                'return_requested',
                'returned',
                'dispute_opened',
                'dispute_closed',
                'escrow_released',
                'admin_action'
            )
        )
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_order_events_order
ON public.order_events(order_id);

CREATE INDEX idx_order_events_profile
ON public.order_events(profile_id);

CREATE INDEX idx_order_events_type
ON public.order_events(event_type);

CREATE INDEX idx_order_events_created
ON public.order_events(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own order events"
ON public.order_events
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.orders o
        WHERE o.id = order_id
        AND (
            o.buyer_id = auth.uid()
            OR o.seller_id = auth.uid()
        )
    )
);

CREATE POLICY "Admins can manage order events"
ON public.order_events
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());