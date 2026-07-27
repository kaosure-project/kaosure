-- =====================================================
-- TABLE : page_views
-- Description : Stores page view history for analytics and user behavior tracking.
-- =====================================================

CREATE TABLE public.page_views (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    session_id UUID
        REFERENCES public.sessions(id)
        ON DELETE SET NULL,

    product_id UUID
        REFERENCES public.products(id)
        ON DELETE SET NULL,

    shop_id UUID
        REFERENCES public.shops(id)
        ON DELETE SET NULL,

    page_name TEXT NOT NULL,

    page_url TEXT,

    referrer TEXT,

    ip_address inet,

    user_agent TEXT,

    platform TEXT,

    country TEXT,

    city TEXT,

    viewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()

);

--------------------------------------------------------
-- INDEXES
--------------------------------------------------------

CREATE INDEX idx_page_views_profile
ON public.page_views(profile_id);

CREATE INDEX idx_page_views_session
ON public.page_views(session_id);

CREATE INDEX idx_page_views_product
ON public.page_views(product_id);

CREATE INDEX idx_page_views_shop
ON public.page_views(shop_id);

CREATE INDEX idx_page_views_viewed
ON public.page_views(viewed_at);

--------------------------------------------------------
-- TRIGGER
--------------------------------------------------------

CREATE TRIGGER update_page_views_updated_at

BEFORE UPDATE
ON public.page_views

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

--------------------------------------------------------
-- ENABLE RLS
--------------------------------------------------------

ALTER TABLE public.page_views
ENABLE ROW LEVEL SECURITY;

--------------------------------------------------------
-- POLICIES
--------------------------------------------------------

CREATE POLICY "Users view own page views"

ON public.page_views

FOR SELECT

USING (
    profile_id = auth.uid()
);

CREATE POLICY "System insert page views"

ON public.page_views

FOR INSERT

WITH CHECK (true);