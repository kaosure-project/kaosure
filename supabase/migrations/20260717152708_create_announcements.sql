CREATE TABLE public.announcements (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    title text NOT NULL,

    content text NOT NULL,

    announcement_type text NOT NULL DEFAULT 'general',

    priority text NOT NULL DEFAULT 'normal',

    is_pinned boolean NOT NULL DEFAULT false,

    is_active boolean NOT NULL DEFAULT true,

    starts_at timestamptz,

    ends_at timestamptz,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT announcements_type_check
        CHECK (
            announcement_type IN (
                'general',
                'maintenance',
                'promotion',
                'event',
                'security'
            )
        ),

    CONSTRAINT announcements_priority_check
        CHECK (
            priority IN (
                'low',
                'normal',
                'high',
                'critical'
            )
        ),

    CONSTRAINT announcements_date_check
        CHECK (
            ends_at IS NULL
            OR starts_at IS NULL
            OR ends_at >= starts_at
        )

);

CREATE INDEX idx_announcements_active
ON public.announcements(is_active);

CREATE INDEX idx_announcements_type
ON public.announcements(announcement_type);

CREATE INDEX idx_announcements_priority
ON public.announcements(priority);

CREATE INDEX idx_announcements_pinned
ON public.announcements(is_pinned);

CREATE INDEX idx_announcements_starts_at
ON public.announcements(starts_at);

ALTER TABLE public.announcements
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view active announcements"
ON public.announcements
FOR SELECT
TO public
USING (
    is_active = true
);

CREATE POLICY "System manage announcements"
ON public.announcements
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_announcements_updated_at
BEFORE UPDATE
ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.announcements IS
'Stores system announcements, maintenance notices, news, and promotional updates.';