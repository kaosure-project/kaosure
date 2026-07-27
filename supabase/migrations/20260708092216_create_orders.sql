-- ==========================================
-- KaoSure Database V1.0
-- Table : orders
-- Business Rule :
-- 1 Product = 1 Order
-- ==========================================

CREATE TABLE public.orders (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    order_number text NOT NULL UNIQUE,

    product_id uuid NOT NULL
        REFERENCES public.products(id)
        ON DELETE RESTRICT,

    buyer_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    seller_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE RESTRICT,

    shop_id uuid NOT NULL
        REFERENCES public.shops(id)
        ON DELETE RESTRICT,

    product_price numeric(12,2) NOT NULL DEFAULT 0,

    shipping_fee numeric(12,2) NOT NULL DEFAULT 0,

    discount_amount numeric(12,2) NOT NULL DEFAULT 0,

    marketplace_fee numeric(12,2) NOT NULL DEFAULT 0,

    total_amount numeric(12,2) NOT NULL DEFAULT 0,

    payment_status text NOT NULL DEFAULT 'pending',

    order_status text NOT NULL DEFAULT 'pending',

    escrow_status text NOT NULL DEFAULT 'holding',

    tracking_number text,

    shipping_company text,

    paid_at timestamptz,

    shipped_at timestamptz,

    delivered_at timestamptz,

    completed_at timestamptz,

    cancelled_at timestamptz,

    cancel_reason text,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_orders_product
ON public.orders(product_id);

CREATE INDEX idx_orders_buyer
ON public.orders(buyer_id);

CREATE INDEX idx_orders_seller
ON public.orders(seller_id);

CREATE INDEX idx_orders_shop
ON public.orders(shop_id);

CREATE INDEX idx_orders_status
ON public.orders(order_status);

CREATE INDEX idx_orders_payment
ON public.orders(payment_status);

CREATE INDEX idx_orders_created
ON public.orders(created_at);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.orders
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view own orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
    auth.uid() = buyer_id
    OR auth.uid() = seller_id
);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can create orders"
ON public.orders
FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = buyer_id
);

-- ==========================================
-- POLICY : UPDATE
-- ==========================================

CREATE POLICY "Users can update own orders"
ON public.orders
FOR UPDATE
TO authenticated
USING (
    auth.uid() = buyer_id
    OR auth.uid() = seller_id
);

-- ==========================================
-- END OF FILE
-- ==========================================