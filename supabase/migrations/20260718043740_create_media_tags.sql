CREATE TABLE public.media_tags (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    media_file_id uuid NOT NULL
        REFERENCES public.media_files(id)
        ON DELETE CASCADE,

    tag_name text NOT NULL,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT media_tags_name_check
        CHECK (length(trim(tag_name)) > 0),

    CONSTRAINT media_tags_unique
        UNIQUE (media_file_id, tag_name)

);

CREATE INDEX idx_media_tags_media_file
ON public.media_tags(media_file_id);

CREATE INDEX idx_media_tags_name
ON public.media_tags(tag_name);

CREATE INDEX idx_media_tags_created_by
ON public.media_tags(created_by);

ALTER TABLE public.media_tags
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view media tags"
ON public.media_tags
FOR SELECT
TO public
USING (true);

CREATE POLICY "System manage media tags"
ON public.media_tags
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

COMMENT ON TABLE public.media_tags IS
'Stores tag assignments for media files.';