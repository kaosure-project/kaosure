-- ==========================================
-- Table: payment_logs
-- ==========================================

CREATE TABLE public.payment_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    payment_transaction_id uuid NOT NULL
        REFERENCES public.payment_transactions(id)
        ON DELETE CASCADE,

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    action text NOT NULL
        CHECK (
            action IN (
                'created',
                'processing',
                'completed',
                'failed',
                'cancelled',
                'refunded',
                'released'
            )
        ),

    description text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    ip_address inet,

    user_agent text,

    created_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_payment_logs_transaction
ON public.payment_logs(payment_transaction_id);

CREATE INDEX idx_payment_logs_profile
ON public.payment_logs(profile_id);

CREATE INDEX idx_payment_logs_action
ON public.payment_logs(action);

CREATE INDEX idx_payment_logs_created
ON public.payment_logs(created_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.payment_logs
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own payment logs"
ON public.payment_logs
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "System can create payment logs"
ON public.payment_logs
FOR INSERT
TO service_role
WITH CHECK (true);

CREATE POLICY "Admins can manage payment logs"
ON public.payment_logs
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());