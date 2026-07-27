CREATE TABLE public.shop_staff (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    shop_id uuid NOT NULL,
    profile_id uuid NOT NULL,

    role text NOT NULL DEFAULT 'staff',

    can_manage_products boolean NOT NULL DEFAULT false,
    can_manage_orders boolean NOT NULL DEFAULT false,
    can_manage_chat boolean NOT NULL DEFAULT false,
    can_manage_staff boolean NOT NULL DEFAULT false,
    can_manage_shop boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    invited_by uuid,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT shop_staff_shop_profile_unique
        UNIQUE(shop_id, profile_id),

    CONSTRAINT shop_staff_shop_id_fkey
        FOREIGN KEY (shop_id)
        REFERENCES public.shops(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT shop_staff_profile_id_fkey
        FOREIGN KEY (profile_id)
        REFERENCES public.profiles(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT shop_staff_invited_by_fkey
        FOREIGN KEY (invited_by)
        REFERENCES public.profiles(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);