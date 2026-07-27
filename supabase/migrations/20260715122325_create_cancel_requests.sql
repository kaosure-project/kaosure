-- ==========================================
-- Table: cancel_requests
-- ==========================================

CREATE TABLE public.cancel_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    requester_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    approved_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    reason text NOT NULL,

    status text NOT NULL DEFAULT 'pending',

    admin_note text,

    requested_at timestamptz NOT NULL DEFAULT now(),

    resolved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT cancel_requests_status_check
    CHECK (
        status IN (
            'pending',
            'approved',
            'rejected',
            'cancelled'
        )
    )
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_cancel_requests_order
ON public.cancel_requests(order_id);

CREATE INDEX idx_cancel_requests_requester
ON public.cancel_requests(requester_id);

CREATE INDEX idx_cancel_requests_status
ON public.cancel_requests(status);

CREATE INDEX idx_cancel_requests_requested
ON public.cancel_requests(requested_at);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_cancel_requests_updated_at
BEFORE UPDATE
ON public.cancel_requests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.cancel_requests ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own cancel requests"
ON public.cancel_requests
FOR SELECT
TO authenticated
USING (
    requester_id = auth.uid()
    OR EXISTS (
        SELECT 1
        FROM public.orders o
        WHERE o.id = order_id
        AND o.seller_id = auth.uid()
    )
);

CREATE POLICY "Users can create cancel requests"
ON public.cancel_requests
FOR INSERT
TO authenticated
WITH CHECK (
    requester_id = auth.uid()
);

CREATE POLICY "Admins can manage cancel requests"
ON public.cancel_requests
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());