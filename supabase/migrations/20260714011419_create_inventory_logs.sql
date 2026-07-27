-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : inventory_logs
-- ============================================================

CREATE TABLE public.inventory_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL,

    variant_id uuid,

    action_type text NOT NULL,

    quantity integer NOT NULL DEFAULT 0,

    quantity_before integer NOT NULL DEFAULT 0,

    quantity_after integer NOT NULL DEFAULT 0,

    reference_type text,

    reference_id uuid,

    note text,

    created_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT inventory_logs_action_type_check
    CHECK (
        action_type IN (
            'stock_in',
            'stock_out',
            'adjustment',
            'return',
            'damage',
            'reserve',
            'release'
        )
    ),

    CONSTRAINT inventory_logs_quantity_check
    CHECK (quantity >= 0),

    CONSTRAINT inventory_logs_quantity_before_check
    CHECK (quantity_before >= 0),

    CONSTRAINT inventory_logs_quantity_after_check
    CHECK (quantity_after >= 0)
);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.inventory_logs IS
'Stores inventory movement history for products and variants.';

COMMENT ON COLUMN public.inventory_logs.product_id IS
'Referenced product';

COMMENT ON COLUMN public.inventory_logs.variant_id IS
'Referenced product variant';

COMMENT ON COLUMN public.inventory_logs.action_type IS
'Inventory movement type';

COMMENT ON COLUMN public.inventory_logs.quantity IS
'Movement quantity';

COMMENT ON COLUMN public.inventory_logs.quantity_before IS
'Stock before transaction';

COMMENT ON COLUMN public.inventory_logs.quantity_after IS
'Stock after transaction';

COMMENT ON COLUMN public.inventory_logs.reference_type IS
'Reference document type';

COMMENT ON COLUMN public.inventory_logs.reference_id IS
'Reference document id';

COMMENT ON COLUMN public.inventory_logs.note IS
'Additional note';

COMMENT ON COLUMN public.inventory_logs.created_by IS
'Operator';

-- ============================================================
-- INDEX
-- ============================================================

CREATE INDEX idx_inventory_logs_product
ON public.inventory_logs(product_id);

CREATE INDEX idx_inventory_logs_variant
ON public.inventory_logs(variant_id);

CREATE INDEX idx_inventory_logs_action
ON public.inventory_logs(action_type);

CREATE INDEX idx_inventory_logs_created_at
ON public.inventory_logs(created_at DESC);

CREATE INDEX idx_inventory_logs_reference
ON public.inventory_logs(reference_type, reference_id);

-- ============================================================
-- updated_at Trigger
-- (ต้องมี function update_updated_at_column() อยู่แล้ว)
-- ============================================================

CREATE TRIGGER inventory_logs_updated_at
BEFORE UPDATE
ON public.inventory_logs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();