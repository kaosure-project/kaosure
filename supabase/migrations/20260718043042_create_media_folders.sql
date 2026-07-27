CREATE TABLE public.media_folders (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_folder_id uuid
        REFERENCES public.media_folders(id)
        ON DELETE SET NULL,

    name text NOT NULL,

    description text,

    created_by uuid
        REFERENCES public.profiles(id)
        ON DELETE SET NULL,

    is_public boolean NOT NULL DEFAULT false,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT media_folders_name_check
        CHECK (
            length(trim(name)) > 0
        )

);

CREATE INDEX idx_media_folders_parent
ON public.media_folders(parent_folder_id);

CREATE INDEX idx_media_folders_creator
ON public.media_folders(created_by);

CREATE INDEX idx_media_folders_public
ON public.media_folders(is_public);

ALTER TABLE public.media_folders
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view public media folders"
ON public.media_folders
FOR SELECT
TO public
USING (is_public = true);

CREATE POLICY "System manage media folders"
ON public.media_folders
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_media_folders_updated_at
BEFORE UPDATE
ON public.media_folders
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.media_folders IS
'Stores virtual folders for organizing uploaded media files.';