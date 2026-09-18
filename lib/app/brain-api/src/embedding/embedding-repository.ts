import type { EmbeddingResult } from "./embedding-service.js";

export type MemoryEmbeddingType =
  | "knowledge"
  | "idea"
  | "decision"
  | "task";

export interface MemoryEmbeddingRecord {
  id: string;
  project_id: string;
  memory_type: MemoryEmbeddingType;
  memory_id: string;
  embedding_model: string;
  embedding_dimension: number;
  embedding: number[];
  content_hash: string;
  created_at: string;
  updated_at: string;
}

export interface MemoryEmbeddingSearchResult {
  memory_type: MemoryEmbeddingType;
  memory_id: string;
  similarity: number;
}

export interface MemoryEmbeddingRepository {
  upsert(
    projectId: string,
    memoryType: MemoryEmbeddingType,
    memoryId: string,
    contentHash: string,
    embedding: EmbeddingResult,
  ): Promise<MemoryEmbeddingRecord>;

  getByMemory(
    memoryType: MemoryEmbeddingType,
    memoryId: string,
  ): Promise<MemoryEmbeddingRecord | null>;

  searchSimilar(
    projectId: string,
    embedding: EmbeddingResult,
    limit?: number,
  ): Promise<MemoryEmbeddingSearchResult[]>;

  deleteByMemory(
    memoryType: MemoryEmbeddingType,
    memoryId: string,
  ): Promise<void>;
}