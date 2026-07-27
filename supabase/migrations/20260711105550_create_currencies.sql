CREATE TABLE public.currencies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    currency_code text NOT NULL,
    currency_name text NOT NULL,
    currency_symbol text NOT NULL,

    exchange_rate numeric(20,8) NOT NULL DEFAULT 1,

    decimal_places int4 NOT NULL DEFAULT 2,

    is_default boolean NOT NULL DEFAULT false,
    is_active boolean NOT NULL DEFAULT true,

    display_order int4 NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.currencies
ADD CONSTRAINT currencies_code_unique
UNIQUE (currency_code);

ALTER TABLE public.currencies
ENABLE ROW LEVEL SECURITY;