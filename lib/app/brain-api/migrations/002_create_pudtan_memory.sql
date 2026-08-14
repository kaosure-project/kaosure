CREATE TABLE IF NOT EXISTS public.pudtan_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  memory_type text NOT NULL
    CHECK (
      memory_type = ANY (
        ARRAY[
          'identity'::text,
          'session_summary'::text,
          'project_context'::text,
          'decision'::text,
          'task_continuity'::text,
          'important_context'::text
        ]
      )
    ),

  title text NOT NULL,

  content text NOT NULL,

  summary text,

  importance text NOT NULL DEFAULT 'normal'
    CHECK (
      importance = ANY (
        ARRAY[
          'low'::text,
          'normal'::text,
          'high'::text,
          'critical'::text
        ]
      )
    ),

  status text NOT NULL DEFAULT 'active'
    CHECK (
      status = ANY (
        ARRAY[
          'active'::text,
          'deprecated'::text
        ]
      )
    ),

  project_id uuid,

  source text NOT NULL DEFAULT 'chatgpt',

  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),

  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT pudtan_memory_project_id_fkey
    FOREIGN KEY (project_id)
    REFERENCES public.brain_projects(id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_pudtan_memory_type
  ON public.pudtan_memory (memory_type);

CREATE INDEX IF NOT EXISTS idx_pudtan_memory_status
  ON public.pudtan_memory (status);

CREATE INDEX IF NOT EXISTS idx_pudtan_memory_project
  ON public.pudtan_memory (project_id);

CREATE INDEX IF NOT EXISTS idx_pudtan_memory_created
  ON public.pudtan_memory (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_pudtan_memory_importance
  ON public.pudtan_memory (importance);