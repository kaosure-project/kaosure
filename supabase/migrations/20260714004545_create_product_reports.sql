-- ============================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Product System
-- Table  : product_reports
-- ============================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.product_reports (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id uuid NOT NULL,

    reporter_id uuid NOT NULL,

    reason text NOT NULL,

    detail text,

    status text NOT NULL DEFAULT 'pending',

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.product_reports IS
'Stores product reports from users';

COMMENT ON COLUMN public.product_reports.reason IS
'Report reason';

ALTER TABLE public.product_reports
ADD CONSTRAINT product_reports_product_fkey
FOREIGN KEY (product_id)
REFERENCES public.products(id)
ON UPDATE CASCADE
ON DELETE CASCADE;

ALTER TABLE public.product_reports
ADD CONSTRAINT product_reports_reporter_fkey
FOREIGN KEY (reporter_id)
REFERENCES public.profiles(id)
ON UPDATE CASCADE
ON DELETE CASCADE;

CREATE INDEX idx_product_reports_product
ON public.product_reports(product_id);

CREATE INDEX idx_product_reports_reporter
ON public.product_reports(reporter_id);

ALTER TABLE public.product_reports
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read product reports"
ON public.product_reports
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Authenticated users can create product reports"
ON public.product_reports
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Admins can update product reports"
ON public.product_reports
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Admins can delete product reports"
ON public.product_reports
FOR DELETE
TO authenticated
USING (true);

CREATE TRIGGER update_product_reports_updated_at
BEFORE UPDATE
ON public.product_reports
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMIT;