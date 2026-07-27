CREATE TABLE public.shop_announcements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    shop_id uuid NOT NULL
        REFERENCES public.shops(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    title text NOT NULL,

    content text,

    announcement_type text DEFAULT 'general',

    start_at timestamptz,

    end_at timestamptz,

    is_pinned boolean DEFAULT false,

    is_active boolean DEFAULT true,

    created_by uuid
        REFERENCES public.profiles(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    created_at timestamptz DEFAULT now(),

    updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.shop_announcements
ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE public.shop_announcements IS
'Stores announcements displayed on shop pages.';