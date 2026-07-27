CREATE TABLE public.pages (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    slug text NOT NULL UNIQUE,

    title text NOT NULL,

    content text NOT NULL,

    page_type text NOT NULL DEFAULT 'page',

    status text NOT NULL DEFAULT 'draft',

    meta_title text,
    meta_description text,

    cover_image_url text,

    published_at timestamptz,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    updated_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pages_page_type_check
        CHECK (
            page_type IN (
                'page',
                'policy',
                'help',
                'landing'
            )
        ),

    CONSTRAINT pages_status_check
        CHECK (
            status IN (
                'draft',
                'published',
                'archived'
            )
        )

);

CREATE INDEX idx_pages_slug
ON public.pages(slug);

CREATE INDEX idx_pages_status
ON public.pages(status);

CREATE INDEX idx_pages_page_type
ON public.pages(page_type);

CREATE INDEX idx_pages_published
ON public.pages(published_at DESC);

ALTER TABLE public.pages
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view published pages"
ON public.pages
FOR SELECT
TO public
USING (
    status = 'published'
);

CREATE POLICY "System manage pages"
ON public.pages
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_pages_updated_at
BEFORE UPDATE
ON public.pages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.pages IS
'Stores CMS pages such as About, Terms, Privacy Policy, Help Center, and other static content.';