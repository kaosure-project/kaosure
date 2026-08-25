-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update Identity Documents V1
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS full_name text;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS country_code text;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS verification_method text;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS verified_at timestamptz;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS verified_by uuid;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS rejected_reason text;

ALTER TABLE public.identity_documents
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

------------------------------------------------------------
-- Default values
------------------------------------------------------------

ALTER TABLE public.identity_documents
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.identity_documents
ALTER COLUMN updated_at SET DEFAULT now();

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_identity_documents_owner
ON public.identity_documents(owner_id);

CREATE INDEX IF NOT EXISTS idx_identity_documents_type
ON public.identity_documents(document_type);

CREATE INDEX IF NOT EXISTS idx_identity_documents_status
ON public.identity_documents(status);

CREATE INDEX IF NOT EXISTS idx_identity_documents_expiry
ON public.identity_documents(expiry_date);

------------------------------------------------------------
-- Foreign Key
------------------------------------------------------------

ALTER TABLE public.identity_documents
DROP CONSTRAINT IF EXISTS identity_documents_verified_by_fkey;

ALTER TABLE public.identity_documents
ADD CONSTRAINT identity_documents_verified_by_fkey
FOREIGN KEY (verified_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;