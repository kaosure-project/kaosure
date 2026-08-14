import { pool } from "../db/postgres.js";

import type {
  MemoryInput,
  MemoryRecord,
} from "./memory-types.js";

import type { MemoryRepository } from "./memory-repository.js";

type MemoryRow = {
  id: string;
  project_id: string;
  title: string;
  content: string | null;
  source: string | null;
  status: string;
  created_at: string;
  updated_at: string;
  memory_type: MemoryInput["type"];
};

function requireProjectId(input: MemoryInput): string {
  if (!input.project_id) {
    throw new Error(
      `project_id is required for memory type "${input.type}".`,
    );
  }

  return input.project_id;
}

function requireTitle(input: MemoryInput): string {
  const title = input.title?.trim();

  if (!title) {
    throw new Error(
      `title is required for memory type "${input.type}".`,
    );
  }

  return title;
}

function toMemoryRecord(row: MemoryRow): MemoryRecord {
  return {
    id: row.id,
    content: row.content ?? "",
    type: row.memory_type,
    importance: "normal",
    source: row.source ?? "",
    project_id: row.project_id,
    title: row.title,
    status:
      row.status === "deprecated" || row.status === "archived"
        ? "deprecated"
        : "active",
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export class PostgresMemoryRepository implements MemoryRepository {
  async create(input: MemoryInput): Promise<MemoryRecord> {
    const projectId = requireProjectId(input);
    const title = requireTitle(input);

    switch (input.type) {
      case "knowledge":
        return this.createKnowledge(input, projectId, title);

      case "idea":
        return this.createIdea(input, projectId, title);

      case "decision":
        return this.createDecision(input, projectId, title);

      case "task":
        return this.createTask(input, projectId, title);

      case "conversation":
      case "current_context":
      case "deprecated":
        throw new Error(
          `Memory type "${input.type}" does not have a persistence mapping yet.`,
        );
    }
  }

  private async createKnowledge(
    input: MemoryInput,
    projectId: string,
    title: string,
  ): Promise<MemoryRecord> {
    const category = input.category ?? "Reference";

    const result = await pool.query<MemoryRow>(
      `
        INSERT INTO public.brain_knowledge (
          project_id,
          title,
          category,
          content,
          source
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
          id,
          project_id,
          title,
          content,
          source,
          status,
          created_at,
          updated_at
      `,
      [
        projectId,
        title,
        category,
        input.content,
        input.source || null,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new Error("Failed to create knowledge memory.");
    }

    return toMemoryRecord({
      ...row,
      memory_type: "knowledge",
    });
  }

  private async createIdea(
    input: MemoryInput,
    projectId: string,
    title: string,
  ): Promise<MemoryRecord> {
    const result = await pool.query<MemoryRow>(
      `
        INSERT INTO public.brain_ideas (
          project_id,
          title,
          description,
          source
        )
        VALUES ($1, $2, $3, $4)
        RETURNING
          id,
          project_id,
          title,
          description AS content,
          source,
          status,
          created_at,
          updated_at
      `,
      [
        projectId,
        title,
        input.content,
        input.source || null,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new Error("Failed to create idea memory.");
    }

    return toMemoryRecord({
      ...row,
      memory_type: "idea",
    });
  }

  private async createDecision(
    input: MemoryInput,
    projectId: string,
    title: string,
  ): Promise<MemoryRecord> {
    const result = await pool.query<MemoryRow>(
      `
        INSERT INTO public.brain_decisions (
          project_id,
          title,
          decision,
          reason,
          impact
        )
        VALUES ($1, $2, $3, $4, $5)
        RETURNING
          id,
          project_id,
          title,
          decision AS content,
          NULL::text AS source,
          status,
          created_at,
          updated_at
      `,
      [
        projectId,
        title,
        input.content,
        input.reason ?? null,
        input.impact ?? null,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new Error("Failed to create decision memory.");
    }

    return toMemoryRecord({
      ...row,
      source: input.source || null,
      memory_type: "decision",
    });
  }

  private async createTask(
    input: MemoryInput,
    projectId: string,
    title: string,
  ): Promise<MemoryRecord> {
    const result = await pool.query<MemoryRow>(
      `
        INSERT INTO public.brain_tasks (
          project_id,
          title,
          description
        )
        VALUES ($1, $2, $3)
        RETURNING
          id,
          project_id,
          title,
          description AS content,
          NULL::text AS source,
          status,
          created_at,
          updated_at
      `,
      [
        projectId,
        title,
        input.content,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new Error("Failed to create task memory.");
    }

    return toMemoryRecord({
      ...row,
      source: input.source || null,
      memory_type: "task",
    });
  }

  async getById(id: string): Promise<MemoryRecord | null> {
    const result = await pool.query<MemoryRow>(
      `
        SELECT
          id,
          project_id,
          title,
          content,
          source,
          status,
          created_at,
          updated_at,
          memory_type
        FROM (
          SELECT
            id,
            project_id,
            title,
            content,
            source,
            status,
            created_at,
            updated_at,
            'knowledge'::text AS memory_type
          FROM public.brain_knowledge

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            source,
            status,
            created_at,
            updated_at,
            'idea'::text AS memory_type
          FROM public.brain_ideas

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            decision AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'decision'::text AS memory_type
          FROM public.brain_decisions

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'task'::text AS memory_type
          FROM public.brain_tasks
        ) AS memories
        WHERE id = $1
        LIMIT 1
      `,
      [id],
    );

    const row = result.rows[0];

    return row ? toMemoryRecord(row) : null;
  }

  async findByProject(
    projectId: string,
  ): Promise<MemoryRecord[]> {
    const result = await pool.query<MemoryRow>(
      `
        SELECT
          id,
          project_id,
          title,
          content,
          source,
          status,
          created_at,
          updated_at,
          memory_type
        FROM (
          SELECT
            id,
            project_id,
            title,
            content,
            source,
            status,
            created_at,
            updated_at,
            'knowledge'::text AS memory_type
          FROM public.brain_knowledge
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            source,
            status,
            created_at,
            updated_at,
            'idea'::text AS memory_type
          FROM public.brain_ideas
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            decision AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'decision'::text AS memory_type
          FROM public.brain_decisions
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'task'::text AS memory_type
          FROM public.brain_tasks
          WHERE project_id = $1
            AND status = 'active'
        ) AS memories
        ORDER BY created_at DESC
      `,
      [projectId],
    );

    return result.rows.map(toMemoryRecord);
  }

  async search(
    projectId: string,
    query: string,
    limit = 10,
  ): Promise<MemoryRecord[]> {
    const normalizedProjectId = projectId.trim();
    const normalizedQuery = query.trim();

    if (!normalizedProjectId || !normalizedQuery) {
      return [];
    }

    const safeLimit = Math.min(
      Math.max(limit, 1),
      50,
    );

    /*
     * Retrieval v3
     *
     * Score:
     *
     * exact phrase       = +100
     * title exact phrase = +80
     * title token match  = +15 each
     * content token      = +10 each
     * source token       = +5 each
     * recency            = small bonus
     *
     * This remains lexical retrieval.
     * Embedding/vector retrieval comes later.
     */

    const result = await pool.query<MemoryRow>(
      `
        WITH memories AS (
          SELECT
            id,
            project_id,
            title,
            content,
            source,
            status,
            created_at,
            updated_at,
            'knowledge'::text AS memory_type,
            category AS search_category
          FROM public.brain_knowledge
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            source,
            status,
            created_at,
            updated_at,
            'idea'::text AS memory_type,
            ''::text AS search_category
          FROM public.brain_ideas
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            decision AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'decision'::text AS memory_type,
            ''::text AS search_category
          FROM public.brain_decisions
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          SELECT
            id,
            project_id,
            title,
            description AS content,
            NULL::text AS source,
            status,
            created_at,
            updated_at,
            'task'::text AS memory_type,
            ''::text AS search_category
          FROM public.brain_tasks
          WHERE project_id = $1
            AND status = 'active'
        ),

        normalized AS (
          SELECT
            memories.*,

            lower(
              regexp_replace(
                concat_ws(
                  ' ',
                  title,
                  content,
                  source,
                  search_category
                ),
                '[_-]',
                ' ',
                'g'
              )
            ) AS searchable_text,

            lower(
              regexp_replace(
                trim($2),
                '[[:punct:]]',
                ' ',
                'g'
              )
            ) AS normalized_query,

            lower(
              regexp_replace(
                coalesce(title, ''),
                '[_-]',
                ' ',
                'g'
              )
            ) AS normalized_title,

            lower(
              regexp_replace(
                coalesce(content, ''),
                '[_-]',
                ' ',
                'g'
              )
            ) AS normalized_content,

            lower(
              regexp_replace(
                coalesce(source, ''),
                '[_-]',
                ' ',
                'g'
              )
            ) AS normalized_source

          FROM memories
        ),

        scored AS (
          SELECT
            normalized.*,

            (
              SELECT count(*)
              FROM regexp_split_to_table(
                normalized.normalized_query,
                '\\s+'
              ) AS query_token
              WHERE length(trim(query_token)) >= 2
                AND (
                  normalized.searchable_text
                    LIKE '%' || trim(query_token) || '%'
                )
            ) AS matched_tokens,

            (
              SELECT count(*)
              FROM regexp_split_to_table(
                normalized.normalized_query,
                '\\s+'
              ) AS query_token
              WHERE length(trim(query_token)) >= 2
                AND normalized.normalized_title
                    LIKE '%' || trim(query_token) || '%'
            ) AS title_matched_tokens,

            (
              SELECT count(*)
              FROM regexp_split_to_table(
                normalized.normalized_query,
                '\\s+'
              ) AS query_token
              WHERE length(trim(query_token)) >= 2
                AND normalized.normalized_content
                    LIKE '%' || trim(query_token) || '%'
            ) AS content_matched_tokens,

            (
              SELECT count(*)
              FROM regexp_split_to_table(
                normalized.normalized_query,
                '\\s+'
              ) AS query_token
              WHERE length(trim(query_token)) >= 2
                AND normalized.normalized_source
                    LIKE '%' || trim(query_token) || '%'
            ) AS source_matched_tokens

          FROM normalized
        ),

        ranked AS (
          SELECT
            scored.*,

            (
              CASE
                WHEN searchable_text
                     LIKE '%' || normalized_query || '%'
                THEN 100
                ELSE 0
              END

              +

              CASE
                WHEN normalized_title
                     LIKE '%' || normalized_query || '%'
                THEN 80
                ELSE 0
              END

              +

              (title_matched_tokens * 15)

              +

              (content_matched_tokens * 10)

              +

              (source_matched_tokens * 5)

              +

              (
                CASE
                  WHEN created_at >= now() - interval '7 days'
                  THEN 5
                  WHEN created_at >= now() - interval '30 days'
                  THEN 3
                  ELSE 1
                END
              )
            ) AS relevance_score

          FROM scored
        )

        SELECT
          id,
          project_id,
          title,
          content,
          source,
          status,
          created_at,
          updated_at,
          memory_type

        FROM ranked

        WHERE matched_tokens > 0

        ORDER BY
          relevance_score DESC,
          matched_tokens DESC,
          title_matched_tokens DESC,
          content_matched_tokens DESC,
          created_at DESC

        LIMIT $3
      `,
      [
        normalizedProjectId,
        normalizedQuery,
        safeLimit,
      ],
    );

    return result.rows.map(toMemoryRecord);
  }

  async findByActor(
    _actorId: string,
  ): Promise<MemoryRecord[]> {
    throw new Error(
      "findByActor is not supported by the current Brain domain schema.",
    );
  }

  async deprecate(
    id: string,
  ): Promise<MemoryRecord | null> {
    const result = await pool.query<MemoryRow>(
      `
        UPDATE public.brain_knowledge
        SET
          status = 'deprecated',
          updated_at = now()
        WHERE id = $1
        RETURNING
          id,
          project_id,
          title,
          content,
          source,
          status,
          created_at,
          updated_at
      `,
      [id],
    );

    const row = result.rows[0];

    if (!row) {
      return null;
    }

    return toMemoryRecord({
      ...row,
      memory_type: "knowledge",
    });
  }
}