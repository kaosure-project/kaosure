-- ============================================
-- TABLE: notification_logs
-- Description:
-- Stores delivery logs for all notifications.
-- ============================================

CREATE TABLE public.notification_logs (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    notification_id UUID NOT NULL
        REFERENCES public.notifications(id)
        ON DELETE CASCADE,

    profile_id UUID NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    delivery_channel TEXT NOT NULL,

    delivery_status TEXT NOT NULL DEFAULT 'pending',

    sent_at TIMESTAMPTZ,

    delivered_at TIMESTAMPTZ,

    error_message TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT notification_logs_channel_check
    CHECK (
        delivery_channel IN (
            'push',
            'email',
            'sms',
            'in_app'
        )
    ),

    CONSTRAINT notification_logs_status_check
    CHECK (
        delivery_status IN (
            'pending',
            'sent',
            'delivered',
            'failed'
        )
    )

);

-------------------------------------------------
-- Indexes
-------------------------------------------------

CREATE INDEX idx_notification_logs_notification
ON public.notification_logs(notification_id);

CREATE INDEX idx_notification_logs_profile
ON public.notification_logs(profile_id);

CREATE INDEX idx_notification_logs_status
ON public.notification_logs(delivery_status);

CREATE INDEX idx_notification_logs_created
ON public.notification_logs(created_at);

-------------------------------------------------
-- Updated At Trigger
-------------------------------------------------

CREATE TRIGGER update_notification_logs_updated_at

BEFORE UPDATE
ON public.notification_logs

FOR EACH ROW

EXECUTE FUNCTION public.update_updated_at_column();

-------------------------------------------------
-- Enable RLS
-------------------------------------------------

ALTER TABLE public.notification_logs
ENABLE ROW LEVEL SECURITY;

-------------------------------------------------
-- Policies
-------------------------------------------------

CREATE POLICY "Users view own notification logs"

ON public.notification_logs

FOR SELECT

USING (
    profile_id = auth.uid()
);

CREATE POLICY "System insert notification logs"

ON public.notification_logs

FOR INSERT

WITH CHECK (true);

