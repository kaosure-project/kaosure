import { pool } from "../db/postgres.js";

import type {
  PudtanMemoryInput,
  PudtanMemoryRecord,
  PudtanMemoryType,
} from "./pudtan-memory-types.js";

export class PudtanMemoryRepository {
  async create(
    input: PudtanMemoryInput,
  ): Promise<PudtanMemoryRecord> {
    const result = await pool.query(
      `
        INSERT INTO public.pudtan_memory (
          memory_type,
          title,
          content,
          summary,
          importance,
          project_id,
          source,
          metadata
        )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6,
          $7,
          $8::jsonb
        )
        RETURNING
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
      `,
      [
        input.memory_type,
        input.title,
        input.content,
        input.summary ?? null,
        input.importance ?? "normal",
        input.project_id ?? null,
        input.source ?? "chatgpt",
        JSON.stringify(input.metadata ?? {}),
      ],
    );

    return this.mapRow(result.rows[0]);
  }

  async getLatest(
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const safeLimit = Math.max(
      1,
      Math.min(limit, 100),
    );

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE status = 'active'
        ORDER BY created_at DESC
        LIMIT $1
      `,
      [safeLimit],
    );

    return result.rows.map((row) =>
      this.mapRow(row),
    );
  }

  async getLatestByProject(
    projectId: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const normalizedProjectId =
      projectId.trim();

    if (!normalizedProjectId) {
      return [];
    }

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100),
    );

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE status = 'active'
          AND project_id = $1
        ORDER BY created_at DESC
        LIMIT $2
      `,
      [
        normalizedProjectId,
        safeLimit,
      ],
    );

    return result.rows.map((row) =>
      this.mapRow(row),
    );
  }

  async search(
    query: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const normalizedQuery = query.trim();

    if (!normalizedQuery) {
      return [];
    }

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100),
    );

    const searchPattern =
      `%${normalizedQuery}%`;

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE status = 'active'
          AND (
            title ILIKE $1
            OR content ILIKE $1
            OR COALESCE(summary, '') ILIKE $1
          )
        ORDER BY
          CASE
            WHEN title ILIKE $1 THEN 0
            WHEN COALESCE(summary, '') ILIKE $1 THEN 1
            ELSE 2
          END,
          created_at DESC
        LIMIT $2
      `,
      [searchPattern, safeLimit],
    );

    return result.rows.map((row) =>
      this.mapRow(row),
    );
  }

  async searchByProject(
    projectId: string,
    query: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedQuery =
      query.trim();

    if (
      !normalizedProjectId ||
      !normalizedQuery
    ) {
      return [];
    }

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100),
    );

    const searchPattern =
      `%${normalizedQuery}%`;

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE status = 'active'
          AND project_id = $1
          AND (
            title ILIKE $2
            OR content ILIKE $2
            OR COALESCE(summary, '') ILIKE $2
          )
        ORDER BY
          CASE
            WHEN title ILIKE $2 THEN 0
            WHEN COALESCE(summary, '') ILIKE $2 THEN 1
            ELSE 2
          END,
          created_at DESC
        LIMIT $3
      `,
      [
        normalizedProjectId,
        searchPattern,
        safeLimit,
      ],
    );

    return result.rows.map((row) =>
      this.mapRow(row),
    );
  }

  async findByContinuityId(
    projectId: string,
    continuityId: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedContinuityId =
      continuityId.trim();

    if (
      !normalizedProjectId ||
      !normalizedContinuityId
    ) {
      return [];
    }

    const safeLimit = Math.max(
      1,
      Math.min(limit, 100),
    );

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE status = 'active'
          AND project_id = $1
          AND metadata->>'continuity_id' = $2
        ORDER BY
          created_at ASC
        LIMIT $3
      `,
      [
        normalizedProjectId,
        normalizedContinuityId,
        safeLimit,
      ],
    );

    return result.rows.map((row) =>
      this.mapRow(row),
    );
  }

  async getById(
    id: string,
  ): Promise<PudtanMemoryRecord | null> {
    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE id = $1
          AND status = 'active'
        LIMIT 1
      `,
      [id],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return this.mapRow(result.rows[0]);
  }

  async getByIdInProject(
    projectId: string,
    id: string,
  ): Promise<PudtanMemoryRecord | null> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedId = id.trim();

    if (
      !normalizedProjectId ||
      !normalizedId
    ) {
      return null;
    }

    const result = await pool.query(
      `
        SELECT
          id,
          memory_type,
          title,
          content,
          summary,
          importance,
          status,
          project_id,
          source,
          metadata,
          created_at,
          updated_at
        FROM public.pudtan_memory
        WHERE id = $1
          AND project_id = $2
          AND status = 'active'
        LIMIT 1
      `,
      [
        normalizedId,
        normalizedProjectId,
      ],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return this.mapRow(result.rows[0]);
  }

  private mapRow(
    row: Record<string, unknown>,
  ): PudtanMemoryRecord {
    const record: PudtanMemoryRecord = {
      id: String(row.id),
      memory_type:
        row.memory_type as PudtanMemoryType,
      title: String(row.title),
      content: String(row.content),
      importance:
        row.importance as PudtanMemoryRecord["importance"],
      status:
        row.status as PudtanMemoryRecord["status"],
      source:
        row.source == null
          ? "chatgpt"
          : String(row.source),
      metadata:
        row.metadata &&
        typeof row.metadata === "object"
          ? (row.metadata as Record<
              string,
              unknown
            >)
          : {},
      created_at:
        row.created_at instanceof Date
          ? row.created_at.toISOString()
          : String(row.created_at),
      updated_at:
        row.updated_at instanceof Date
          ? row.updated_at.toISOString()
          : String(row.updated_at),
    };

    if (row.summary != null) {
      record.summary = String(row.summary);
    }

    if (row.project_id != null) {
      record.project_id =
        String(row.project_id);
    }

    return record;
  }
}