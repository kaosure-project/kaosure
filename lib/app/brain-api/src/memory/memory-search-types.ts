import type { MemoryRecord } from "./memory-types.js";

export interface MemorySearchItem {
  memory: MemoryRecord;
  score: number;
  matched_tokens: number;
  exact_match: boolean;
  title_match: boolean;
}

export interface MemorySearchResult {
  query: string;
  project_id: string;
  count: number;
  memories: MemorySearchItem[];
}