CREATE TABLE public.banners (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    title text NOT NULL,

    description text,

    image_url text NOT NULL,

    mobile_image_url text,

    link_url text,

    button_text text,

    banner_type text NOT NULL DEFAULT 'promotion',

    position text NOT NULL DEFAULT 'homepage',

    display_order integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    starts_at timestamptz,

    ends_at timestamptz,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT banners_banner_type_check
        CHECK (
            banner_type IN (
                'promotion',
                'campaign',
                'announcement',
                'system'
            )
        ),

    CONSTRAINT banners_position_check
        CHECK (
            position IN (
                'homepage',
                'category',
                'product',
                'seller',
                'event'
            )
        ),

    CONSTRAINT banners_date_check
        CHECK (
            ends_at IS NULL
            OR starts_at IS NULL
            OR ends_at >= starts_at
        )

);

CREATE INDEX idx_banners_active
ON public.banners(is_active);

CREATE INDEX idx_banners_position
ON public.banners(position);

CREATE INDEX idx_banners_display_order
ON public.banners(display_order);

CREATE INDEX idx_banners_starts_at
ON public.banners(starts_at);

ALTER TABLE public.banners
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active banners"
ON public.banners
FOR SELECT
TO public
USING (
    is_active = true
);

CREATE POLICY "System manage banners"
ON public.banners
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_banners_updated_at
BEFORE UPDATE
ON public.banners
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.banners IS
'Stores homepage banners, promotional campaigns, and marketing advertisements.';