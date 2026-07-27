-- ==========================================
-- Table: tags
-- ==========================================

CREATE TABLE public.tags (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    name text NOT NULL UNIQUE,

    slug text NOT NULL UNIQUE,

    description text,

    color text,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Index
-- ==========================================

CREATE INDEX idx_tags_name
ON public.tags(name);

CREATE INDEX idx_tags_slug
ON public.tags(slug);

CREATE INDEX idx_tags_active
ON public.tags(is_active);

-- ==========================================
-- Trigger
-- ==========================================

CREATE TRIGGER update_tags_updated_at
BEFORE UPDATE
ON public.tags
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.tags ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Everyone can view tags"
ON public.tags
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can manage tags"
ON public.tags
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());