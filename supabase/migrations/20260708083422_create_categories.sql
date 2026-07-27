-- ==========================================
-- KaoSure Database V1.0
-- Table : categories
-- ==========================================

CREATE TABLE public.categories (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id uuid
        REFERENCES public.categories(id)
        ON DELETE SET NULL,

    name text NOT NULL,

    slug text NOT NULL UNIQUE,

    icon text,

    image_url text,

    description text,

    sort_order integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_categories_parent
ON public.categories(parent_id);

CREATE INDEX idx_categories_slug
ON public.categories(slug);

CREATE INDEX idx_categories_active
ON public.categories(is_active);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.categories
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view categories"
ON public.categories
FOR SELECT
TO authenticated
USING (true);

-- ==========================================
-- END OF FILE
-- ==========================================