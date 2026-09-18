export type PudtanMemoryType =
  | "identity"
  | "session_summary"
  | "project_context"
  | "decision"
  | "task_continuity"
  | "important_context";

export type PudtanMemoryImportance =
  | "low"
  | "normal"
  | "high"
  | "critical";

export type PudtanMemoryStatus =
  | "active"
  | "deprecated";

export interface PudtanMemoryInput {
  memory_type: PudtanMemoryType;
  title: string;
  content: string;
  summary?: string;
  importance?: PudtanMemoryImportance;
  project_id?: string;
  source?: string;
  metadata?: Record<string, unknown>;
}

export interface PudtanMemoryRecord
  extends PudtanMemoryInput {
  id: string;
  importance: PudtanMemoryImportance;
  status: PudtanMemoryStatus;
  source: string;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}