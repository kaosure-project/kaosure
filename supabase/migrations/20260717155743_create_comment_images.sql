CREATE TABLE public.comment_images (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    comment_id uuid NOT NULL
        REFERENCES public.product_comments(id)
        ON DELETE CASCADE,

    uploaded_by uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    image_url text NOT NULL,

    storage_path text NOT NULL,

    original_file_name text,

    mime_type text NOT NULL,

    file_size bigint NOT NULL,

    display_order integer NOT NULL DEFAULT 0,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT comment_images_file_size_check
        CHECK (file_size > 0)

);

CREATE INDEX idx_comment_images_comment
ON public.comment_images(comment_id);

CREATE INDEX idx_comment_images_uploaded_by
ON public.comment_images(uploaded_by);

CREATE INDEX idx_comment_images_display_order
ON public.comment_images(display_order);

ALTER TABLE public.comment_images
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can view comment images"
ON public.comment_images
FOR SELECT
TO public
USING (true);

CREATE POLICY "Users upload own comment images"
ON public.comment_images
FOR INSERT
TO authenticated
WITH CHECK (
    uploaded_by = auth.uid()
);

CREATE POLICY "System manage comment images"
ON public.comment_images
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.comment_images IS
'Stores image attachments for product comments.';