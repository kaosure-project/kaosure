CREATE TABLE public.support_tickets (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    ticket_number text NOT NULL UNIQUE,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    assigned_admin_id uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    category text NOT NULL,

    priority text NOT NULL DEFAULT 'normal',

    status text NOT NULL DEFAULT 'open',

    subject text NOT NULL,

    description text NOT NULL,

    first_response_at timestamptz,
    resolved_at timestamptz,
    closed_at timestamptz,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT support_tickets_category_check
        CHECK (
            category IN (
                'account',
                'payment',
                'order',
                'shipping',
                'product',
                'seller',
                'buyer',
                'report',
                'technical',
                'other'
            )
        ),

    CONSTRAINT support_tickets_priority_check
        CHECK (
            priority IN (
                'low',
                'normal',
                'high',
                'urgent'
            )
        ),

    CONSTRAINT support_tickets_status_check
        CHECK (
            status IN (
                'open',
                'pending',
                'resolved',
                'closed'
            )
        )

);

CREATE INDEX idx_support_tickets_profile
ON public.support_tickets(profile_id);

CREATE INDEX idx_support_tickets_admin
ON public.support_tickets(assigned_admin_id);

CREATE INDEX idx_support_tickets_status
ON public.support_tickets(status);

CREATE INDEX idx_support_tickets_priority
ON public.support_tickets(priority);

CREATE INDEX idx_support_tickets_created
ON public.support_tickets(created_at DESC);

ALTER TABLE public.support_tickets
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own support tickets"
ON public.support_tickets
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Users create own support tickets"
ON public.support_tickets
FOR INSERT
TO authenticated
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users update own open support tickets"
ON public.support_tickets
FOR UPDATE
TO authenticated
USING (
    profile_id = auth.uid()
    AND status = 'open'
)
WITH CHECK (
    profile_id = auth.uid()
);

CREATE POLICY "System manage support tickets"
ON public.support_tickets
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_support_tickets_updated_at
BEFORE UPDATE
ON public.support_tickets
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.support_tickets IS
'Stores customer support tickets between users and administrators.';