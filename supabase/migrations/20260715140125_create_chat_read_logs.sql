-- ==========================================
-- Table: chat_read_logs
-- ==========================================

CREATE TABLE public.chat_read_logs (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    room_id uuid NOT NULL
        REFERENCES public.chat_rooms(id)
        ON DELETE CASCADE,

    message_id uuid
        REFERENCES public.chat_messages(id)
        ON DELETE CASCADE,

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    read_at timestamptz NOT NULL DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now()
);

-- ==========================================
-- Indexes
-- ==========================================

CREATE INDEX idx_chat_read_logs_room
ON public.chat_read_logs(room_id);

CREATE INDEX idx_chat_read_logs_message
ON public.chat_read_logs(message_id);

CREATE INDEX idx_chat_read_logs_profile
ON public.chat_read_logs(profile_id);

CREATE INDEX idx_chat_read_logs_read_at
ON public.chat_read_logs(read_at);

-- ==========================================
-- Enable RLS
-- ==========================================

ALTER TABLE public.chat_read_logs
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Policies
-- ==========================================

CREATE POLICY "Users can create read logs"
ON public.chat_read_logs
FOR INSERT
TO authenticated
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can view own read logs"
ON public.chat_read_logs
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Admins can manage read logs"
ON public.chat_read_logs
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.seller_level = 'admin'
    )
);

-- ==========================================
-- Description
-- ==========================================

COMMENT ON TABLE public.chat_read_logs IS
'Stores message read receipts for chat conversations.';