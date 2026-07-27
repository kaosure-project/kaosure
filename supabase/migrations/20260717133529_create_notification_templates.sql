CREATE TABLE public.notification_templates (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    code text NOT NULL UNIQUE,
    name text NOT NULL,

    category text NOT NULL,

    title_template text NOT NULL,
    body_template text NOT NULL,

    notification_type text NOT NULL,

    is_active boolean NOT NULL DEFAULT true,

    variables jsonb NOT NULL DEFAULT '[]'::jsonb,

    description text,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT notification_templates_category_check
        CHECK (
            category IN (
                'system',
                'marketplace',
                'order',
                'payment',
                'shipping',
                'chat',
                'promotion',
                'security'
            )
        ),

    CONSTRAINT notification_templates_type_check
        CHECK (
            notification_type IN (
                'push',
                'email',
                'sms',
                'in_app'
            )
        )

);

CREATE INDEX idx_notification_templates_code
ON public.notification_templates(code);

CREATE INDEX idx_notification_templates_category
ON public.notification_templates(category);

CREATE INDEX idx_notification_templates_type
ON public.notification_templates(notification_type);

CREATE INDEX idx_notification_templates_active
ON public.notification_templates(is_active);

ALTER TABLE public.notification_templates
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view active notification templates"
ON public.notification_templates
FOR SELECT
TO authenticated
USING (is_active = true);

CREATE POLICY "System manage notification templates"
ON public.notification_templates
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_notification_templates_updated_at
BEFORE UPDATE
ON public.notification_templates
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.notification_templates IS
'Stores reusable notification templates for push, email, SMS, and in-app notifications.';