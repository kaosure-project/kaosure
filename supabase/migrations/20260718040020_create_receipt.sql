CREATE TABLE public.receipt (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    receipt_number text NOT NULL UNIQUE,

    invoice_id uuid
        REFERENCES public.invoice(id)
        ON DELETE SET NULL,

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE RESTRICT,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    tax_record_id uuid
        REFERENCES public.tax_records(id)
        ON DELETE SET NULL,

    tax_name text,
    tax_id text,
    tax_address text,
    branch_number text,

    subtotal_amount numeric(15,2) NOT NULL,

    tax_amount numeric(15,2) NOT NULL DEFAULT 0,

    total_amount numeric(15,2) NOT NULL,

    payment_method text,

    currency_code text NOT NULL DEFAULT 'THB',

    status text NOT NULL DEFAULT 'issued',

    issued_at timestamptz NOT NULL DEFAULT now(),

    paid_at timestamptz,

    notes text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT receipt_status_check
        CHECK (
            status IN (
                'issued',
                'cancelled',
                'void'
            )
        ),

    CONSTRAINT receipt_amount_check
        CHECK (
            subtotal_amount >= 0
            AND tax_amount >= 0
            AND total_amount >= 0
        )

);

CREATE INDEX idx_receipt_number
ON public.receipt(receipt_number);

CREATE INDEX idx_receipt_invoice
ON public.receipt(invoice_id);

CREATE INDEX idx_receipt_order
ON public.receipt(order_id);

CREATE INDEX idx_receipt_profile
ON public.receipt(profile_id);

CREATE INDEX idx_receipt_tax_record
ON public.receipt(tax_record_id);

CREATE INDEX idx_receipt_issued_at
ON public.receipt(issued_at DESC);

ALTER TABLE public.receipt
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own receipts"
ON public.receipt
FOR SELECT
TO authenticated
USING (
    profile_id = auth.uid()
);

CREATE POLICY "System manage receipts"
ON public.receipt
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_receipt_updated_at
BEFORE UPDATE
ON public.receipt
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.receipt IS
'Stores payment receipts with tax information snapshot for accounting and auditing.';