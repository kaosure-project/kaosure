CREATE TABLE public.ai_embeddings (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    training_id uuid
        REFERENCES public.ai_training(id)
        ON DELETE SET NULL,

    entity_type text NOT NULL,

    entity_id uuid NOT NULL,

    embedding_model text NOT NULL,

    embedding_dimension integer NOT NULL,

    embedding_version integer NOT NULL DEFAULT 1,

    embedding jsonb,
    content_hash text,

    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

    created_at timestamptz NOT NULL DEFAULT now(),

    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT ai_embeddings_entity_type_check
        CHECK (
            entity_type IN (
                'product',
                'shop',
                'category',
                'brand',
                'user',
                'article',
                'custom'
            )
        ),

    CONSTRAINT ai_embeddings_dimension_check
        CHECK (
            embedding_dimension > 0
        ),

    CONSTRAINT ai_embeddings_version_check
        CHECK (
            embedding_version > 0
        )

);

CREATE INDEX idx_ai_embeddings_training
ON public.ai_embeddings(training_id);

CREATE INDEX idx_ai_embeddings_entity
ON public.ai_embeddings(entity_type, entity_id);

CREATE INDEX idx_ai_embeddings_model
ON public.ai_embeddings(embedding_model);

CREATE INDEX idx_ai_embeddings_hash
ON public.ai_embeddings(content_hash);

ALTER TABLE public.ai_embeddings
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System manage ai embeddings"
ON public.ai_embeddings
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_ai_embeddings_updated_at
BEFORE UPDATE
ON public.ai_embeddings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.ai_embeddings IS
'Stores AI embedding vectors and metadata generated from AI training jobs.';