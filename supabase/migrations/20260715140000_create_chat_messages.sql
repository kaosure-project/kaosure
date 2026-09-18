-- ==========================================
-- KaoSure Database
-- Table : chat_messages
-- Description : Messages inside chat rooms
-- ==========================================

CREATE TABLE public.chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    room_id uuid NOT NULL
        REFERENCES public.chat_rooms(id)
        ON DELETE CASCADE,

    sender_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    message text NOT NULL,

    message_type text NOT NULL DEFAULT 'text'
        CHECK (
            message_type IN (
                'text',
                'image',
                'file',
                'system'
            )
        ),

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    edited_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT chat_messages_message_check
        CHECK (
            length(trim(message)) > 0
        )
);

-- ==========================================
-- INDEXES
-- ==========================================

CREATE INDEX idx_chat_messages_room
ON public.chat_messages(room_id);

CREATE INDEX idx_chat_messages_sender
ON public.chat_messages(sender_id);

CREATE INDEX idx_chat_messages_created
ON public.chat_messages(created_at DESC);

CREATE INDEX idx_chat_messages_room_created
ON public.chat_messages(room_id, created_at DESC);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.chat_messages
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICIES
-- ==========================================

CREATE POLICY "Users can view chat messages"
ON public.chat_messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.chat_rooms cr
        WHERE cr.id = room_id
        AND (
            cr.buyer_id = auth.uid()
            OR cr.seller_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can send chat messages"
ON public.chat_messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.chat_rooms cr
        WHERE cr.id = room_id
        AND (
            cr.buyer_id = auth.uid()
            OR cr.seller_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can update own chat messages"
ON public.chat_messages
FOR UPDATE
TO authenticated
USING (
    sender_id = auth.uid()
)
WITH CHECK (
    sender_id = auth.uid()
);

-- ==========================================
-- TRIGGER
-- ==========================================

CREATE TRIGGER update_chat_messages_updated_at
BEFORE UPDATE
ON public.chat_messages
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ==========================================
-- COMMENT
-- ==========================================

COMMENT ON TABLE public.chat_messages IS
'Stores messages exchanged inside chat rooms.';