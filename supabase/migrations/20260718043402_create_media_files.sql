CREATE TABLE public.media_files (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    folder_id uuid
        REFERENCES public.media_folders(id)
        ON DELETE SET NULL,

    uploaded_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    storage_bucket text NOT NULL,

    storage_path text NOT NULL,

    original_filename text NOT NULL,

    file_name text NOT NULL,

    mime_type text NOT NULL,

    file_extension text,

    file_size bigint NOT NULL,

    width integer,

    height integer,

    checksum text,

    is_public boolean NOT NULL DEFAULT false,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT media_files_size_check
        CHECK (file_size >= 0),

    CONSTRAINT media_files_dimension_check
        CHECK (
            (width IS NULL OR width >= 0)
            AND
            (height IS NULL OR height >= 0)
        )

);

CREATE INDEX idx_media_files_folder
ON public.media_files(folder_id);

CREATE INDEX idx_media_files_uploaded_by
ON public.media_files(uploaded_by);

CREATE INDEX idx_media_files_bucket
ON public.media_files(storage_bucket);

CREATE INDEX idx_media_files_path
ON public.media_files(storage_path);

CREATE INDEX idx_media_files_public
ON public.media_files(is_public);

CREATE INDEX idx_media_files_mime
ON public.media_files(mime_type);

ALTER TABLE public.media_files
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view public media files"
ON public.media_files
FOR SELECT
TO public
USING (is_public = true);

CREATE POLICY "System manage media files"
ON public.media_files
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_media_files_updated_at
BEFORE UPDATE
ON public.media_files
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.media_files IS
'Stores metadata for uploaded media files managed by Supabase Storage.';