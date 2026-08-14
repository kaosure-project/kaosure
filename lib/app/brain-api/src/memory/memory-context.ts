import type { MemoryRecord } from "./memory-types.js";

export interface MemoryRetrievalEvidence {
  semantic_score: number;
  combined_score: number;
  source_quality: number;
  query_relevance: number;
  semantic_rank: number | null;
  lexical_rank: number | null;
}

export interface MemoryContextItem {
  id: string;
  type: MemoryRecord["type"];
  title: string;
  content: string;
  source: string;
  importance: MemoryRecord["importance"];
  retrieval_evidence?: MemoryRetrievalEvidence;
}

export interface MemoryContext {
  query: string;
  project_id: string;
  count: number;
  memories: MemoryContextItem[];
  text: string;
}

export interface MemoryContextInput {
  memory: MemoryRecord;
  retrieval_evidence?: MemoryRetrievalEvidence;
}

export function buildMemoryContext(
  query: string,
  projectId: string,
  memories: MemoryRecord[],
): MemoryContext {
  return buildMemoryContextWithEvidence(
    query,
    projectId,
    memories.map((memory) => ({
      memory,
    })),
  );
}

export function buildMemoryContextWithEvidence(
  query: string,
  projectId: string,
  memories: MemoryContextInput[],
): MemoryContext {
  const items: MemoryContextItem[] =
  memories.map(
    ({
      memory,
      retrieval_evidence,
    }) => ({
      id: memory.id,
      type: memory.type,
      title:
        memory.title ??
        "(untitled)",
      content: memory.content,
      source: memory.source,
      importance: memory.importance,

      ...(retrieval_evidence
        ? {
            retrieval_evidence,
          }
        : {}),
    }),
  );

  const text = items
    .map(
      (memory, index) =>
        [
          `[Memory ${index + 1}]`,
          `Type: ${memory.type}`,
          `Title: ${memory.title}`,
          `Content: ${memory.content}`,
          `Source: ${
            memory.source || "unknown"
          }`,
        ].join("\n"),
    )
    .join("\n\n");

  return {
    query,
    project_id: projectId,
    count: items.length,
    memories: items,
    text,
  };
}