-- ==========================================
-- Table: disputes
-- ==========================================

CREATE TABLE public.disputes (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    buyer_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    seller_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    created_by uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    dispute_type text NOT NULL
        CHECK (
            dispute_type IN (
                'item_not_received',
                'item_not_as_described',
                'damaged',
                'fake_item',
                'payment_issue',
                'other'
            )
        ),

    title text NOT NULL,

    description text NOT NULL,

    status text NOT NULL DEFAULT 'open'
        CHECK (
            status IN (
                'open',
                'under_review',
                'waiting_response',
                'resolved',
                'rejected',
                'closed'
            )
        ),

    admin_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    resolution text,

    resolved_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_disputes_order
ON public.disputes(order_id);

CREATE INDEX idx_disputes_buyer
ON public.disputes(buyer_id);

CREATE INDEX idx_disputes_seller
ON public.disputes(seller_id);

CREATE INDEX idx_disputes_status
ON public.disputes(status);

CREATE INDEX idx_disputes_created
ON public.disputes(created_at);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_disputes_updated_at
BEFORE UPDATE ON public.disputes
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.disputes
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can create disputes"
ON public.disputes
FOR INSERT
TO authenticated
WITH CHECK (
    created_by = auth.uid()
);

CREATE POLICY "Users can view own disputes"
ON public.disputes
FOR SELECT
TO authenticated
USING (
    buyer_id = auth.uid()
    OR seller_id = auth.uid()
    OR created_by = auth.uid()
);

CREATE POLICY "Admins can manage disputes"
ON public.disputes
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.seller_level = 'admin'
    )
);

-- ==========================================
-- Description
-- ==========================================

COMMENT ON TABLE public.disputes IS
'Stores buyer and seller dispute cases for orders.';