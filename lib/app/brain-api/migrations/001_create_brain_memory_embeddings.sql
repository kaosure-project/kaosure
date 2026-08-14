CREATE TABLE IF NOT EXISTS public.brain_memory_embeddings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  project_id uuid NOT NULL,

  memory_type text NOT NULL
    CHECK (
      memory_type = ANY (
        ARRAY[
          'knowledge'::text,
          'idea'::text,
          'decision'::text,
          'task'::text
        ]
      )
    ),

  memory_id uuid NOT NULL,

  embedding_model text NOT NULL,

  embedding_dimension integer NOT NULL
    CHECK (embedding_dimension = 1536),

  embedding vector(1536) NOT NULL,

  content_hash text NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),

  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT brain_memory_embeddings_unique
    UNIQUE (
      memory_type,
      memory_id,
      embedding_model
    )
);

CREATE INDEX IF NOT EXISTS idx_brain_memory_embeddings_project
  ON public.brain_memory_embeddings (project_id);

CREATE INDEX IF NOT EXISTS idx_brain_memory_embeddings_memory
  ON public.brain_memory_embeddings (
    memory_type,
    memory_id
  );

CREATE INDEX IF NOT EXISTS idx_brain_memory_embeddings_model
  ON public.brain_memory_embeddings (embedding_model);

CREATE INDEX IF NOT EXISTS idx_brain_memory_embeddings_hash
  ON public.brain_memory_embeddings (content_hash);

CREATE INDEX IF NOT EXISTS idx_brain_memory_embeddings_vector_hnsw
  ON public.brain_memory_embeddings
  USING hnsw (embedding vector_cosine_ops);
