CREATE TABLE public.invoice (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    invoice_number text NOT NULL UNIQUE,

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE RESTRICT,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    tax_record_id uuid
        REFERENCES public.tax_records(id)
        ON DELETE SET NULL,

    subtotal_amount numeric(15,2) NOT NULL,

    tax_amount numeric(15,2) NOT NULL DEFAULT 0,

    total_amount numeric(15,2) NOT NULL,

    currency_code text NOT NULL DEFAULT 'THB',

    status text NOT NULL DEFAULT 'issued',

    issued_at timestamptz NOT NULL DEFAULT now(),

    due_at timestamptz,

    paid_at timestamptz,

    notes text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT invoice_status_check
        CHECK (
            status IN (
                'draft',
                'issued',
                'paid',
                'cancelled',
                'void'
            )
        ),

    CONSTRAINT invoice_amount_check
        CHECK (
            subtotal_amount >= 0
            AND tax_amount >= 0
            AND total_amount >= 0
        )

);

CREATE INDEX idx_invoice_number
ON public.invoice(invoice_number);

CREATE INDEX idx_invoice_order
ON public.invoice(order_id);

CREATE INDEX idx_invoice_profile
ON public.invoice(profile_id);

CREATE INDEX idx_invoice_tax_record
ON public.invoice(tax_record_id);

CREATE INDEX idx_invoice_status
ON public.invoice(status);

CREATE INDEX idx_invoice_issued_at
ON public.invoice(issued_at DESC);

ALTER TABLE public.invoice
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own invoices"
ON public.invoice
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "System manage invoices"
ON public.invoice
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_invoice_updated_at
BEFORE UPDATE
ON public.invoice
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.invoice IS
'Stores invoices issued for completed marketplace transactions.';