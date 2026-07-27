-- ==========================================
-- Table: cart_items
-- ==========================================

CREATE TABLE public.cart_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    cart_id uuid NOT NULL
        REFERENCES public.carts(id)
        ON DELETE CASCADE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE CASCADE,

    quantity integer NOT NULL DEFAULT 1
        CHECK (quantity > 0),

    selected boolean NOT NULL DEFAULT true,

    price_snapshot numeric(15,2) NOT NULL
        CHECK (price_snapshot >= 0),

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT cart_items_unique_product
        UNIQUE(cart_id, product_id)
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_cart_items_cart
ON public.cart_items(cart_id);

CREATE INDEX idx_cart_items_product
ON public.cart_items(product_id);

CREATE INDEX idx_cart_items_created
ON public.cart_items(created_at);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_cart_items_updated_at
BEFORE UPDATE ON public.cart_items
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can manage own cart items"
ON public.cart_items
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.carts c
        WHERE c.id = cart_id
        AND c.user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.carts c
        WHERE c.id = cart_id
        AND c.user_id = auth.uid()
    )
);

CREATE POLICY "Users can view own cart items"
ON public.cart_items
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.carts c
        WHERE c.id = cart_id
        AND c.user_id = auth.uid()
    )
);