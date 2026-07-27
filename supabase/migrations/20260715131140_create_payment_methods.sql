-- ==========================================
-- Table: payment_methods
-- ==========================================

CREATE TABLE public.payment_methods (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    method_type text NOT NULL
        CHECK (
            method_type IN (
                'bank_account',
                'credit_card',
                'debit_card',
                'promptpay',
                'wallet',
                'paypal',
                'other'
            )
        ),

    provider text NOT NULL,

    account_name text,

    account_number text,

    is_default boolean NOT NULL DEFAULT false,

    is_verified boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_payment_methods_profile
ON public.payment_methods(profile_id);

CREATE INDEX idx_payment_methods_type
ON public.payment_methods(method_type);

CREATE INDEX idx_payment_methods_active
ON public.payment_methods(is_active);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_payment_methods_updated_at
BEFORE UPDATE
ON public.payment_methods
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.payment_methods
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own payment methods"
ON public.payment_methods
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Users can insert own payment methods"
ON public.payment_methods
FOR INSERT
TO authenticated
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "Users can update own payment methods"
ON public.payment_methods
FOR UPDATE
TO authenticated
USING (
    profile_id = auth.uid()
)
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "Users can delete own payment methods"
ON public.payment_methods
FOR DELETE
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "Admins can manage payment methods"
ON public.payment_methods
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());