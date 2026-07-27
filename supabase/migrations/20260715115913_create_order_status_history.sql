-- ==========================================
-- Table: order_status_history
-- ==========================================

CREATE TABLE public.order_status_history (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    changed_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    old_status text,

    new_status text NOT NULL,

    note text,

    created_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_order_status_history_order
ON public.order_status_history(order_id);

CREATE INDEX idx_order_status_history_changed_by
ON public.order_status_history(changed_by);

CREATE INDEX idx_order_status_history_new_status
ON public.order_status_history(new_status);

CREATE INDEX idx_order_status_history_created
ON public.order_status_history(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own order status history"
ON public.order_status_history
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

CREATE POLICY "Admins can manage order status history"
ON public.order_status_history
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());