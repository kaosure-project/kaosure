-- =========================================================
-- KAOSURE
-- Migration : create_system_settings
-- Description : Global system configuration
-- =========================================================

CREATE TABLE public.system_settings (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    setting_key text NOT NULL UNIQUE,

    setting_name text NOT NULL,

    setting_value text,

    value_type text NOT NULL DEFAULT 'string'
        CHECK (
            value_type IN (
                'string',
                'integer',
                'decimal',
                'boolean',
                'json'
            )
        ),

    category text NOT NULL DEFAULT 'general',

    description text,

    is_public boolean NOT NULL DEFAULT false,

    is_editable boolean NOT NULL DEFAULT true,

    display_order integer NOT NULL DEFAULT 0,

    created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,

    updated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now()

);

COMMENT ON TABLE public.system_settings IS
'Stores configurable system settings used across the KaoSure marketplace.';

COMMENT ON COLUMN public.system_settings.setting_key IS
'Unique system setting key.';

COMMENT ON COLUMN public.system_settings.setting_value IS
'Current setting value.';

COMMENT ON COLUMN public.system_settings.value_type IS
'Data type of setting value.';

COMMENT ON COLUMN public.system_settings.category IS
'Setting category.';

COMMENT ON COLUMN public.system_settings.is_public IS
'Can frontend read this setting.';

COMMENT ON COLUMN public.system_settings.is_editable IS
'Can admin edit this setting.';

CREATE INDEX idx_system_settings_category
ON public.system_settings(category);

CREATE INDEX idx_system_settings_public
ON public.system_settings(is_public);

CREATE INDEX idx_system_settings_display_order
ON public.system_settings(display_order);