CREATE TABLE public.tax_records (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    tax_type text NOT NULL,

    tax_id text NOT NULL,

    business_name text,

    branch_number text,

    tax_address text,

    country_code text NOT NULL DEFAULT 'TH',

    is_default boolean NOT NULL DEFAULT false,

    verified_at timestamptz,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT tax_records_tax_type_check
        CHECK (
            tax_type IN (
                'personal',
                'business'
            )
        )

);

CREATE INDEX idx_tax_records_profile
ON public.tax_records(profile_id);

CREATE INDEX idx_tax_records_tax_id
ON public.tax_records(tax_id);

CREATE INDEX idx_tax_records_default
ON public.tax_records(is_default);

ALTER TABLE public.tax_records
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own tax records"
ON public.tax_records
FOR ALL
TO authenticated
USING (
    profile_id = auth.uid()
)
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "System manage tax records"
ON public.tax_records
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_tax_records_updated_at
BEFORE UPDATE
ON public.tax_records
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.tax_records IS
'Stores tax information for users, sellers, and business entities.';