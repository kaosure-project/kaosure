CREATE TABLE public.seller_levels (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    level_name text NOT NULL,
    level_code text NOT NULL,

    badge_color text,
    badge_icon text,

    min_completed_orders integer NOT NULL DEFAULT 0,
    min_rating numeric(3,2) NOT NULL DEFAULT 0,

    commission_rate numeric(5,2) NOT NULL DEFAULT 10,

    payout_delay_days integer NOT NULL DEFAULT 7,

    max_active_products integer,

    can_join_campaign boolean NOT NULL DEFAULT false,
    can_livestream boolean NOT NULL DEFAULT false,
    priority_support boolean NOT NULL DEFAULT false,

    description text,

    display_order integer NOT NULL DEFAULT 0,

    is_active boolean NOT NULL DEFAULT true,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT seller_levels_code_unique UNIQUE(level_code)
);