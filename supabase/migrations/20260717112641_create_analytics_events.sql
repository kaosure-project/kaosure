-- =====================================================
-- TABLE : analytics_events
-- Description : Stores all user activity events
-- =====================================================

CREATE TABLE public.analytics_events (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id UUID
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    product_id UUID
        REFERENCES public.products(id)
        ON DELETE SET NULL,

    shop_id UUID
        REFERENCES public.shops(id)
        ON DELETE SET NULL,

    session_id UUID
        REFERENCES public.sessions(id)
        ON DELETE SET NULL,

    event_type TEXT NOT NULL,

    event_name TEXT NOT NULL,

    page TEXT,

    referrer TEXT,

    ip_address inet,

    user_agent TEXT,

    device_type TEXT,

    platform TEXT,

    country TEXT,

    city TEXT,

    metadata JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_events_event_type_check
    CHECK (
        event_type IN (
            'page_view',
            'click',
            'search',
            'favorite',
            'cart',
            'purchase',
            'login',
            'logout',
            'share',
            'other'
        )
    )

);

--------------------------------------------------------
-- INDEX
--------------------------------------------------------

CREATE INDEX idx_analytics_events_profile
ON public.analytics_events(profile_id);

CREATE INDEX idx_analytics_events_product
ON public.analytics_events(product_id);

CREATE INDEX idx_analytics_events_shop
ON public.analytics_events(shop_id);

CREATE INDEX idx_analytics_events_session
ON public.analytics_events(session_id);

CREATE INDEX idx_analytics_events_type
ON public.analytics_events(event_type);

CREATE INDEX idx_analytics_events_created
ON public.analytics_events(created_at);

--------------------------------------------------------
-- Trigger
--------------------------------------------------------

CREATE TRIGGER update_analytics_events_updated_at

BEFORE UPDATE
ON public.analytics_events

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

--------------------------------------------------------
-- Enable RLS
--------------------------------------------------------

ALTER TABLE public.analytics_events
ENABLE ROW LEVEL SECURITY;

--------------------------------------------------------
-- Policies
--------------------------------------------------------

CREATE POLICY "Users view own analytics"

ON public.analytics_events

FOR SELECT

USING (
    profile_id = auth.uid()
);

CREATE POLICY "System insert analytics"

ON public.analytics_events

FOR INSERT

WITH CHECK (true);