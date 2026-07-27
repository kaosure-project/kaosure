CREATE TABLE public.faq (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    help_article_id uuid
        REFERENCES public.help_articles(id)
        ON DELETE SET NULL,

    question text NOT NULL,

    answer text NOT NULL,

    category text NOT NULL,

    sort_order integer NOT NULL DEFAULT 0,

    is_featured boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    view_count bigint NOT NULL DEFAULT 0,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    updated_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT faq_question_check
        CHECK (length(trim(question)) > 0),

    CONSTRAINT faq_answer_check
        CHECK (length(trim(answer)) > 0)

);

CREATE INDEX idx_faq_help_article
ON public.faq(help_article_id);

CREATE INDEX idx_faq_category
ON public.faq(category);

CREATE INDEX idx_faq_active
ON public.faq(is_active);

CREATE INDEX idx_faq_featured
ON public.faq(is_featured);

CREATE INDEX idx_faq_sort_order
ON public.faq(sort_order);

ALTER TABLE public.faq
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active FAQ"
ON public.faq
FOR SELECT
TO public
USING (
    is_active = true
);

CREATE POLICY "System manage FAQ"
ON public.faq
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_faq_updated_at
BEFORE UPDATE
ON public.faq
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.faq IS
'Stores frequently asked questions with optional links to Help Center articles.';