-- ==========================================
-- Table: order_items
-- ==========================================

CREATE TABLE public.order_items (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id uuid NOT NULL
        REFERENCES public.orders(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE RESTRICT,

    variant_id uuid
        REFERENCES public.product_variants(id)
        ON DELETE SET NULL,

    seller_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    product_name text NOT NULL,

    variant_name text,

    sku text,

    quantity integer NOT NULL DEFAULT 1,

    unit_price numeric(12,2) NOT NULL,

    subtotal numeric(12,2) NOT NULL,

    discount_amount numeric(12,2) NOT NULL DEFAULT 0,

    shipping_fee numeric(12,2) NOT NULL DEFAULT 0,

    tax_amount numeric(12,2) NOT NULL DEFAULT 0,

    total_amount numeric(12,2) NOT NULL,

    order_status text NOT NULL DEFAULT 'pending',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT order_items_quantity_check
        CHECK (quantity > 0),

    CONSTRAINT order_items_price_check
        CHECK (
            unit_price >= 0
            AND subtotal >= 0
            AND total_amount >= 0
        ),

    CONSTRAINT order_items_status_check
        CHECK (
            order_status IN (
                'pending',
                'paid',
                'packing',
                'shipped',
                'delivered',
                'completed',
                'cancelled',
                'refunded',
                'returned'
            )
        )
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_order_items_order
ON public.order_items(order_id);

CREATE INDEX idx_order_items_product
ON public.order_items(product_id);

CREATE INDEX idx_order_items_variant
ON public.order_items(variant_id);

CREATE INDEX idx_order_items_seller
ON public.order_items(seller_id);

CREATE INDEX idx_order_items_status
ON public.order_items(order_status);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_order_items_updated_at
BEFORE UPDATE
ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.order_items
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can view own order items"
ON public.order_items
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.orders o
        WHERE o.id = order_id
        AND (
            o.buyer_id = auth.uid()
            OR seller_id = auth.uid()
        )
    )
);

CREATE POLICY "Admins can manage order items"
ON public.order_items
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());