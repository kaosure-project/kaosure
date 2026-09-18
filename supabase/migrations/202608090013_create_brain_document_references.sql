-- ============================================================
-- Kao Brain
-- Table: brain_document_references
-- Purpose: Links Brain entities to source documents
-- ============================================================

CREATE TABLE public.brain_document_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    entity_type TEXT NOT NULL,

    entity_id UUID NOT NULL,

    file_path TEXT NOT NULL,

    section TEXT,

    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_brain_document_references_entity
ON public.brain_document_references(entity_type, entity_id);

CREATE INDEX idx_brain_document_references_file
ON public.brain_document_references(file_path);

CREATE INDEX idx_brain_document_references_created
ON public.brain_document_references(created_at DESC);

COMMENT ON TABLE public.brain_document_references IS
'Links Kao Brain entities to their source documents in the repository.';

COMMENT ON COLUMN public.brain_document_references.entity_type IS
'Type of Brain entity referenced by the document.';

COMMENT ON COLUMN public.brain_document_references.entity_id IS
'Identifier of the Brain entity referenced by the document.';

COMMENT ON COLUMN public.brain_document_references.file_path IS
'Repository-relative path of the source document.';

COMMENT ON COLUMN public.brain_document_references.section IS
'Optional section or heading within the source document.';

COMMENT ON COLUMN public.brain_document_references.description IS
'Description of why the document is relevant to the entity.';