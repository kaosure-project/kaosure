CREATE TABLE public.notification_settings (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    push_enabled boolean NOT NULL DEFAULT true,
    email_enabled boolean NOT NULL DEFAULT true,
    sms_enabled boolean NOT NULL DEFAULT false,

    marketplace_notifications boolean NOT NULL DEFAULT true,
    order_notifications boolean NOT NULL DEFAULT true,
    payment_notifications boolean NOT NULL DEFAULT true,
    shipping_notifications boolean NOT NULL DEFAULT true,
    chat_notifications boolean NOT NULL DEFAULT true,
    promotion_notifications boolean NOT NULL DEFAULT true,
    security_notifications boolean NOT NULL DEFAULT true,

    quiet_hours_enabled boolean NOT NULL DEFAULT false,
    quiet_hours_start time,
    quiet_hours_end time,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT notification_settings_profile_unique
        UNIQUE (profile_id),

    CONSTRAINT notification_settings_quiet_hours_check
        CHECK (
            (quiet_hours_enabled = false)
            OR
            (
                quiet_hours_start IS NOT NULL
                AND quiet_hours_end IS NOT NULL
            )
        )
);

CREATE INDEX idx_notification_settings_profile
ON public.notification_settings(profile_id);

ALTER TABLE public.notification_settings
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own notification settings"
ON public.notification_settings
FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "System manage notification settings"
ON public.notification_settings
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_notification_settings_updated_at
BEFORE UPDATE
ON public.notification_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.notification_settings IS
'Stores notification preferences and delivery settings for each user.';