-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : product_tag_relations
-- ============================================================

BEGIN;

---------------------------------------------------------------
-- CREATE TABLE
---------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.product_tag_relations (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL,

    tag_id uuid NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now()

);

---------------------------------------------------------------
-- COMMENT
---------------------------------------------------------------

COMMENT ON TABLE public.product_tag_relations
IS 'Relation table between products and tags';

COMMENT ON COLUMN public.product_tag_relations.product_id
IS 'Reference to products';

COMMENT ON COLUMN public.product_tag_relations.tag_id
IS 'Reference to product tags';

---------------------------------------------------------------
-- FOREIGN KEY
---------------------------------------------------------------

ALTER TABLE public.product_tag_relations

ADD CONSTRAINT product_tag_relations_product_fkey

FOREIGN KEY (product_id)

REFERENCES public.products(id)

ON UPDATE CASCADE

ON DELETE CASCADE;

ALTER TABLE public.product_tag_relations

ADD CONSTRAINT product_tag_relations_tag_fkey

FOREIGN KEY (tag_id)

REFERENCES public.product_tags(id)

ON UPDATE CASCADE

ON DELETE CASCADE;

---------------------------------------------------------------
-- UNIQUE
---------------------------------------------------------------

ALTER TABLE public.product_tag_relations

ADD CONSTRAINT product_tag_relations_unique

UNIQUE(product_id,tag_id);

---------------------------------------------------------------
-- INDEX
---------------------------------------------------------------

CREATE INDEX idx_product_tag_relations_product

ON public.product_tag_relations(product_id);

CREATE INDEX idx_product_tag_relations_tag

ON public.product_tag_relations(tag_id);

---------------------------------------------------------------
-- ENABLE RLS
---------------------------------------------------------------

ALTER TABLE public.product_tag_relations

ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY "Authenticated users can read product tag relations"

ON public.product_tag_relations

FOR SELECT

TO authenticated

USING (true);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY "Admins can create product tag relations"

ON public.product_tag_relations

FOR INSERT

TO authenticated

WITH CHECK (true);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY "Admins can update product tag relations"

ON public.product_tag_relations

FOR UPDATE

TO authenticated

USING (true)

WITH CHECK (true);

---------------------------------------------------------------
-- DELETE
---------------------------------------------------------------

CREATE POLICY "Admins can delete product tag relations"

ON public.product_tag_relations

FOR DELETE

TO authenticated

USING (true);

---------------------------------------------------------------
-- UPDATED_AT TRIGGER
---------------------------------------------------------------

-- ไม่มี updated_at
-- ตารางนี้จึงไม่ต้องใช้ Trigger

COMMIT;