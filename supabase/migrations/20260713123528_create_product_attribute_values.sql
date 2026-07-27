-- ==========================================
-- TABLE: product_attribute_values
-- ==========================================

CREATE TABLE public.product_attribute_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    attribute_id UUID NOT NULL,

    value TEXT NOT NULL,

    slug TEXT NOT NULL,

    display_order INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT product_attribute_values_attribute_fkey
        FOREIGN KEY(attribute_id)
        REFERENCES public.product_attributes(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE public.product_attribute_values IS
'Stores selectable values for each product attribute.';

ALTER TABLE public.product_attribute_values
ADD CONSTRAINT product_attribute_values_unique
UNIQUE(attribute_id, slug);

ALTER TABLE public.product_attribute_values
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read attribute values"
ON public.product_attribute_values
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can create attribute values"
ON public.product_attribute_values
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins can update attribute values"
ON public.product_attribute_values
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can delete attribute values"
ON public.product_attribute_values
FOR DELETE
TO authenticated
USING (true);