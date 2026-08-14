import { createHash } from "node:crypto";

import { pool } from "../db/postgres.js";

import type { EmbeddingResult } from "./embedding-service.js";
import type {
  MemoryEmbeddingRecord,
  MemoryEmbeddingRepository,
  MemoryEmbeddingSearchResult,
  MemoryEmbeddingType,
} from "./embedding-repository.js";

type MemoryEmbeddingRow = {
  id: string;
  project_id: string;
  memory_type: MemoryEmbeddingType;
  memory_id: string;
  embedding_model: string;
  embedding_dimension: number;
  embedding: string;
  content_hash: string;
  created_at: string;
  updated_at: string;
};

function toVectorLiteral(values: number[]): string {
  if (values.length === 0) {
    throw new Error("Embedding vector must not be empty.");
  }

  if (!values.every(Number.isFinite)) {
    throw new Error("Embedding vector contains a non-finite value.");
  }

  return `[${values.join(",")}]`;
}

function toEmbeddingRecord(
  row: MemoryEmbeddingRow,
): MemoryEmbeddingRecord {
  const parsed = JSON.parse(row.embedding);

  if (!Array.isArray(parsed)) {
    throw new Error("Stored embedding is not a vector array.");
  }

  return {
    id: row.id,
    project_id: row.project_id,
    memory_type: row.memory_type,
    memory_id: row.memory_id,
    embedding_model: row.embedding_model,
    embedding_dimension: row.embedding_dimension,
    embedding: parsed.map(Number),
    content_hash: row.content_hash,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function createContentHash(content: string): string {
  return createHash("sha256")
    .update(content, "utf8")
    .digest("hex");
}

export class PostgresMemoryEmbeddingRepository
  implements MemoryEmbeddingRepository
{
  async upsert(
    projectId: string,
    memoryType: MemoryEmbeddingType,
    memoryId: string,
    contentHash: string,
    embedding: EmbeddingResult,
  ): Promise<MemoryEmbeddingRecord> {
    const vector = toVectorLiteral(embedding.embedding);

    const result = await pool.query<MemoryEmbeddingRow>(
      `
        INSERT INTO public.brain_memory_embeddings (
          project_id,
          memory_type,
          memory_id,
          embedding_model,
          embedding_dimension,
          embedding,
          content_hash
        )
        VALUES (
          $1,
          $2,
          $3,
          $4,
          $5,
          $6::vector,
          $7
        )
        ON CONFLICT (
          memory_type,
          memory_id,
          embedding_model
        )
        DO UPDATE SET
          project_id = EXCLUDED.project_id,
          embedding_dimension = EXCLUDED.embedding_dimension,
          embedding = EXCLUDED.embedding,
          content_hash = EXCLUDED.content_hash,
          updated_at = now()
        RETURNING
          id,
          project_id,
          memory_type,
          memory_id,
          embedding_model,
          embedding_dimension,
          embedding::text AS embedding,
          content_hash,
          created_at,
          updated_at
      `,
      [
        projectId,
        memoryType,
        memoryId,
        embedding.model,
        embedding.dimensions,
        vector,
        contentHash,
      ],
    );

    const row = result.rows[0];

    if (!row) {
      throw new Error(
        "Failed to upsert memory embedding.",
      );
    }

    return toEmbeddingRecord(row);
  }

  async getByMemory(
    memoryType: MemoryEmbeddingType,
    memoryId: string,
  ): Promise<MemoryEmbeddingRecord | null> {
    const result = await pool.query<MemoryEmbeddingRow>(
      `
        SELECT
          id,
          project_id,
          memory_type,
          memory_id,
          embedding_model,
          embedding_dimension,
          embedding::text AS embedding,
          content_hash,
          created_at,
          updated_at
        FROM public.brain_memory_embeddings
        WHERE memory_type = $1
          AND memory_id = $2
        ORDER BY updated_at DESC
        LIMIT 1
      `,
      [memoryType, memoryId],
    );

    const row = result.rows[0];

    return row
      ? toEmbeddingRecord(row)
      : null;
  }

  async searchSimilar(
    projectId: string,
    embedding: EmbeddingResult,
    limit = 10,
  ): Promise<MemoryEmbeddingSearchResult[]> {
    if (!Number.isInteger(limit) || limit <= 0) {
      throw new Error(
        "Semantic search limit must be a positive integer.",
      );
    }

    const vector = toVectorLiteral(embedding.embedding);

    const result = await pool.query<{
      memory_type: MemoryEmbeddingType;
      memory_id: string;
      similarity: number;
    }>(
      `
        SELECT
          memory_type,
          memory_id,
          1 - (embedding <=> $1::vector) AS similarity
        FROM public.brain_memory_embeddings
        WHERE project_id = $2
          AND embedding_model = $3
          AND embedding_dimension = $4
        ORDER BY embedding <=> $1::vector
        LIMIT $5
      `,
      [
        vector,
        projectId,
        embedding.model,
        embedding.dimensions,
        limit,
      ],
    );

    return result.rows.map((row) => ({
      memory_type: row.memory_type,
      memory_id: row.memory_id,
      similarity: Number(row.similarity),
    }));
  }

  async deleteByMemory(
    memoryType: MemoryEmbeddingType,
    memoryId: string,
  ): Promise<void> {
    await pool.query(
      `
        DELETE FROM public.brain_memory_embeddings
        WHERE memory_type = $1
          AND memory_id = $2
      `,
      [memoryType, memoryId],
    );
  }
}