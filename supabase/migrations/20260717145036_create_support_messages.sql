CREATE TABLE public.support_messages (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    ticket_id uuid NOT NULL
        REFERENCES public.support_tickets(id)
        ON DELETE CASCADE,

    sender_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    message_type text NOT NULL DEFAULT 'text',

    message text NOT NULL,

    is_internal boolean NOT NULL DEFAULT false,

    is_read boolean NOT NULL DEFAULT false,

    read_at timestamptz,

    edited_at timestamptz,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT support_messages_message_type_check
        CHECK (
            message_type IN (
                'text',
                'system'
            )
        ),

    CONSTRAINT support_messages_message_check
        CHECK (
            length(trim(message)) > 0
        )

);

CREATE INDEX idx_support_messages_ticket
ON public.support_messages(ticket_id);

CREATE INDEX idx_support_messages_sender
ON public.support_messages(sender_id);

CREATE INDEX idx_support_messages_created
ON public.support_messages(created_at DESC);

CREATE INDEX idx_support_messages_read
ON public.support_messages(is_read);

ALTER TABLE public.support_messages
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view messages in own tickets"
ON public.support_messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id
          AND st.profile_id = auth.uid()
    )
);

CREATE POLICY "Users send messages to own tickets"
ON public.support_messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.support_tickets st
        WHERE st.id = ticket_id
          AND st.profile_id = auth.uid()
    )
);

CREATE POLICY "System manage support messages"
ON public.support_messages
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_support_messages_updated_at
BEFORE UPDATE
ON public.support_messages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.support_messages IS
'Stores conversation messages between users and support staff within support tickets.';