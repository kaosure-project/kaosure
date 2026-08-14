export type MemoryType =
  | "conversation"
  | "idea"
  | "decision"
  | "task"
  | "knowledge"
  | "current_context"
  | "deprecated";

export type MemoryImportance =
  | "low"
  | "normal"
  | "high"
  | "critical";

export type MemoryStatus =
  | "active"
  | "deprecated";

export interface MemoryInput {
  content: string;
  type: MemoryType;
  importance: MemoryImportance;
  source: string;

  /**
   * Common identity / trace fields.
   */
  source_id?: string;
  actor_id?: string;
  project_id?: string;
  created_at?: string;

  /**
   * Optional domain title.
   *
   * Required by brain_ideas, brain_decisions,
   * brain_tasks and brain_knowledge at persistence time.
   */
  title?: string;

  /**
   * Knowledge domain.
   * brain_knowledge.category has a database CHECK constraint.
   */
  category?:
    | "Technical"
    | "Coding"
    | "Architecture"
    | "Development"
    | "AI"
    | "Reference";

  /**
   * Decision domain.
   */
  reason?: string;
  impact?: string;

  /**
   * Task domain.
   */
  current_state?: string;
  expected_result?: string;
  blocked_reason?: string;

  /**
   * Generic structured metadata.
   *
   * This is kept at the application layer for now.
   * It should not be persisted blindly because the
   * current domain tables have different JSONB fields.
   */
  metadata?: Record<string, unknown>;
}

export interface MemoryRecord extends MemoryInput {
  id: string;
  status: MemoryStatus;
  created_at: string;
  updated_at: string;
}