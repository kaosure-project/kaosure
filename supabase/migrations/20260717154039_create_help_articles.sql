CREATE TABLE public.help_articles (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    slug text NOT NULL UNIQUE,

    title text NOT NULL,

    summary text,

    content text NOT NULL,

    category text NOT NULL,

    tags text[] NOT NULL DEFAULT '{}',

    sort_order integer NOT NULL DEFAULT 0,

    is_featured boolean NOT NULL DEFAULT false,

    status text NOT NULL DEFAULT 'draft',

    view_count bigint NOT NULL DEFAULT 0,

    published_at timestamptz,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    updated_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT help_articles_status_check
        CHECK (
            status IN (
                'draft',
                'published',
                'archived'
            )
        )

);

CREATE INDEX idx_help_articles_slug
ON public.help_articles(slug);

CREATE INDEX idx_help_articles_category
ON public.help_articles(category);

CREATE INDEX idx_help_articles_status
ON public.help_articles(status);

CREATE INDEX idx_help_articles_featured
ON public.help_articles(is_featured);

CREATE INDEX idx_help_articles_published
ON public.help_articles(published_at DESC);

ALTER TABLE public.help_articles
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view published help articles"
ON public.help_articles
FOR SELECT
TO public
USING (
    status = 'published'
);

CREATE POLICY "System manage help articles"
ON public.help_articles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_help_articles_updated_at
BEFORE UPDATE
ON public.help_articles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.help_articles IS
'Stores Help Center articles, tutorials, user guides, and knowledge base content.';