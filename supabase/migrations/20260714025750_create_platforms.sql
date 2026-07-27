-- =====================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Core System
-- Table  : platforms
-- =====================================================

CREATE TABLE public.platforms (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    code text NOT NULL,
    name text NOT NULL,

    description text,

    website_url text,

    logo_url text,

    is_active boolean NOT NULL DEFAULT true,

    display_order integer NOT NULL DEFAULT 0,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.platforms IS
'Stores all KaoSure platforms such as Marketplace, Auction, Live, Auto.';

COMMENT ON COLUMN public.platforms.code IS
'Unique platform code';

COMMENT ON COLUMN public.platforms.name IS
'Platform name';

COMMENT ON COLUMN public.platforms.website_url IS
'Official website URL';

COMMENT ON COLUMN public.platforms.logo_url IS
'Platform logo';

COMMENT ON COLUMN public.platforms.display_order IS
'Display order';

ALTER TABLE public.platforms
ADD CONSTRAINT platforms_code_unique
UNIQUE (code);

ALTER TABLE public.platforms
ADD CONSTRAINT platforms_display_order_check
CHECK (display_order >= 0);

CREATE INDEX idx_platforms_code
ON public.platforms(code);

CREATE INDEX idx_platforms_active
ON public.platforms(is_active);

CREATE INDEX idx_platforms_display_order
ON public.platforms(display_order);

CREATE OR REPLACE FUNCTION public.update_platforms_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_platforms_updated_at
BEFORE UPDATE
ON public.platforms
FOR EACH ROW
EXECUTE FUNCTION public.update_platforms_updated_at();

ALTER TABLE public.platforms
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read platforms"
ON public.platforms
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can create platforms"
ON public.platforms
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Admins can update platforms"
ON public.platforms
FOR UPDATE
TO authenticated
USING (true);

CREATE POLICY "Admins can delete platforms"
ON public.platforms
FOR DELETE
TO authenticated
USING (true);

INSERT INTO public.platforms
(code,name,description,display_order)
VALUES
('market','KaoSure Marketplace','Marketplace Platform',1),
('auction','KaoSure Auction','Auction Platform',2);
