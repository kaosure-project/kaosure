CREATE TABLE public.ticket_files (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    message_id uuid NOT NULL
        REFERENCES public.support_messages(id)
        ON DELETE CASCADE,

    uploaded_by uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    file_name text NOT NULL,

    original_file_name text NOT NULL,

    storage_path text NOT NULL,

    mime_type text NOT NULL,

    file_extension text,

    file_size bigint NOT NULL,

    checksum text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ticket_files_file_size_check
        CHECK (file_size > 0)

);

CREATE INDEX idx_ticket_files_message
ON public.ticket_files(message_id);

CREATE INDEX idx_ticket_files_uploaded_by
ON public.ticket_files(uploaded_by);

CREATE INDEX idx_ticket_files_created
ON public.ticket_files(created_at DESC);

ALTER TABLE public.ticket_files
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own ticket files"
ON public.ticket_files
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.support_messages sm
        JOIN public.support_tickets st
            ON st.id = sm.ticket_id
        WHERE sm.id = message_id
          AND st.profile_id = auth.uid()
    )
);

CREATE POLICY "Users upload ticket files"
ON public.ticket_files
FOR INSERT
TO authenticated
WITH CHECK (
    uploaded_by = auth.uid()
);

CREATE POLICY "System manage ticket files"
ON public.ticket_files
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.ticket_files IS
'Stores attachments uploaded to support ticket conversations.';