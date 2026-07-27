-- ==========================================
-- Table: dispute_messages
-- ==========================================

CREATE TABLE public.dispute_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    dispute_id uuid NOT NULL
        REFERENCES public.disputes(id)
        ON DELETE CASCADE,

    sender_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    message text NOT NULL,

    message_type text NOT NULL DEFAULT 'text'
        CHECK (
            message_type IN (
                'text',
                'image',
                'file',
                'system'
            )
        ),

    is_internal boolean NOT NULL DEFAULT false,

    created_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.dispute_messages IS
'Stores chat messages exchanged during dispute resolution.';

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_dispute_messages_dispute
ON public.dispute_messages(dispute_id);

CREATE INDEX idx_dispute_messages_sender
ON public.dispute_messages(sender_id);

CREATE INDEX idx_dispute_messages_created
ON public.dispute_messages(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.dispute_messages ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Admins can manage dispute messages"
ON public.dispute_messages
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
    )
);

CREATE POLICY "Users can create dispute messages"
ON public.dispute_messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid()
);

CREATE POLICY "Users can view dispute messages"
ON public.dispute_messages
FOR SELECT
TO authenticated
USING (
    sender_id = auth.uid()
    OR EXISTS (
        SELECT 1
        FROM public.disputes d
        WHERE d.id = dispute_id
        AND (
            d.buyer_id = auth.uid()
            OR d.seller_id = auth.uid()
            OR d.created_by = auth.uid()
            OR d.admin_id = auth.uid()
        )
    )
);