import type { MemoryRecallResult } from "./memory-service.js";
import { MemoryService } from "./memory-service.js";

import {
  ProjectStateReader,
  type ProjectState,
} from "./project-state-reader.js";

import {
  OrganizationalConsistencyChecker,
  type OrganizationalConsistencyResult,
} from "./organizational-consistency-checker.js";

/**
 * Complete context assembled for Pudtan reasoning.
 *
 * This is the boundary between:
 *
 * 1. Organizational State
 * 2. Organizational Memory
 * 3. Retrieval confidence
 * 4. Organizational consistency
 *
 * and the AI reasoning layer.
 *
 * IMPORTANT:
 *
 * Retrieval Confidence and Organizational Consistency
 * are intentionally separate concepts.
 *
 * Retrieval Confidence answers:
 *   "How strongly does retrieved memory support this query?"
 *
 * Organizational Consistency answers:
 *   "Do the organizational state and organizational
 *    memory provide a coherent organizational picture?"
 */
export interface BrainContextAssembly {
  project_state: ProjectState;

  memory_context: MemoryRecallResult;

  organizational_consistency:
    OrganizationalConsistencyResult;

  assembled_text: string;
}

export class BrainContextAssembler {
  constructor(
    private readonly projectStateReader: ProjectStateReader,
    private readonly memoryService: MemoryService,
    private readonly organizationalConsistencyChecker:
      OrganizationalConsistencyChecker,
  ) {}

  /**
   * Assemble the organizational context required
   * for reasoning about a user query.
   *
   * Reads:
   *
   * - Organizational State
   * - Organizational Memory
   * - Organizational Consistency
   *
   * No mutation is performed by this assembler.
   */
  async assemble(
    projectId: string,
    query: string,
    limit = 5,
  ): Promise<BrainContextAssembly> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedQuery =
      query.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedQuery) {
      throw new Error(
        "query is required.",
      );
    }

    const normalizedLimit =
      this.normalizeLimit(limit);

    /**
     * These are independent read operations.
     *
     * Organizational Consistency is intentionally
     * delegated to the dedicated deterministic checker.
     */
    const [
      projectState,
      memoryContext,
      organizationalConsistency,
    ] = await Promise.all([
      this.projectStateReader.getProjectState(
        normalizedProjectId,
      ),

      this.memoryService.recall(
        normalizedProjectId,
        normalizedQuery,
        normalizedLimit,
      ),

      this.organizationalConsistencyChecker.check(
        normalizedProjectId,
      ),
    ]);

    const assembledText =
      this.buildAssemblyText(
        projectState,
        memoryContext,
        organizationalConsistency,
      );

    return {
      project_state: projectState,
      memory_context: memoryContext,
      organizational_consistency:
        organizationalConsistency,
      assembled_text: assembledText,
    };
  }

  /**
   * Convert organizational state,
   * retrieval diagnostics,
   * consistency diagnostics,
   * and retrieved memories
   * into deterministic reasoning context.
   *
   * IMPORTANT:
   *
   * Retrieval Agreement is NOT Organizational Conflict.
   *
   * A semantic/lexical disagreement belongs under
   * Retrieval Diagnostics only.
   */
  private buildAssemblyText(
    projectState: ProjectState,
    memoryContext: MemoryRecallResult,
    organizationalConsistency:
      OrganizationalConsistencyResult,
  ): string {
    const context =
      projectState.context;

    /**
     * --------------------------------------------------
     * 1. Organizational State
     * --------------------------------------------------
     */
    const projectSection = [
      "[ORGANIZATIONAL STATE]",

      `Project: ${
        projectState.project.name
      }`,

      `Status: ${
        projectState.project.status
      }`,

      `Phase: ${
        context?.current_phase ??
        "unknown"
      }`,

      `Focus: ${
        context?.current_focus ??
        "unknown"
      }`,

      `Objective: ${
        context?.current_objective ??
        "unknown"
      }`,

      `Priority: ${
        context?.current_priority ??
        "unknown"
      }`,

      `Next Step: ${
        context?.next_step ??
        "unknown"
      }`,

      `State Updated At: ${
        context?.updated_at ??
        "unknown"
      }`,

      "",

      "Progress:",

      context?.current_progress ??
        "unknown",

      "",

      "Blockers:",

      context?.current_blockers ??
        "unknown",
    ].join("\n");

    /**
     * --------------------------------------------------
     * 2. Retrieval Diagnostics
     * --------------------------------------------------
     *
     * These values come directly from MemoryService.
     *
     * MemoryRecallResult explicitly exposes:
     * - recalled
     * - retrieval
     *
     * and retrieval contains:
     * - confidence
     * - confidence_score
     * - semantic_result_count
     * - lexical_result_count
     * - similarities
     * - top memory IDs
     * - retrieval_agreement
     * - reason
     */
    const retrieval =
      memoryContext.retrieval;

    const retrievalSection = [
      "[RETRIEVAL DIAGNOSTICS]",

      `Recalled: ${
        memoryContext.recalled
      }`,

      `Confidence: ${
        retrieval.confidence
      }`,

      `Confidence Score: ${
        retrieval.confidence_score
      }`,

      `Top Similarity: ${
        retrieval.top_similarity
      }`,

      `Second Similarity: ${
        retrieval.second_similarity
      }`,

      `Semantic Results: ${
        retrieval.semantic_result_count
      }`,

      `Lexical Results: ${
        retrieval.lexical_result_count
      }`,

      `Retrieval Agreement: ${
        retrieval.retrieval_agreement
      }`,

      `Semantic Top Memory ID: ${
        retrieval.semantic_top_memory_id ??
        "none"
      }`,

      `Lexical Top Memory ID: ${
        retrieval.lexical_top_memory_id ??
        "none"
      }`,

      `Reason: ${
        retrieval.reason
      }`,
    ].join("\n");

    /**
     * --------------------------------------------------
     * 3. Organizational Consistency
     * --------------------------------------------------
     *
     * This comes exclusively from
     * OrganizationalConsistencyChecker.
     *
     * Do NOT mix retrieval disagreement into this section.
     */
    const consistencyIssues =
      organizationalConsistency.issues
        .map((issue) => {
          const evidence =
            issue.evidence;

          const evidenceText = [
            evidence.source,
            evidence.id
              ? `id=${evidence.id}`
              : null,
            evidence.updated_at
              ? `updated_at=${evidence.updated_at}`
              : null,
          ]
            .filter(
              (
                value,
              ): value is string =>
                Boolean(value),
            )
            .join(" ");

          return [
            `- [${issue.severity}]`,
            issue.type,
            issue.message,
            evidenceText
              ? `(${evidenceText})`
              : "",
          ]
            .filter(
              (value) =>
                value.length > 0,
            )
            .join(" ");
        });

    const consistencySection = [
      "[ORGANIZATIONAL CONSISTENCY]",

      `Status: ${
        organizationalConsistency.status
      }`,

      `Score: ${
        organizationalConsistency.score
      }`,

      `Checked At: ${
        organizationalConsistency.checked_at
      }`,

      `State Updated At: ${
        organizationalConsistency.state_updated_at ??
        "unknown"
      }`,

      `Latest Memory Updated At: ${
        organizationalConsistency.latest_memory_updated_at ??
        "unknown"
      }`,

      "",

      "Issues:",

      ...(consistencyIssues.length > 0
        ? consistencyIssues
        : ["- none"]),

      "",

      `Summary: ${
        organizationalConsistency.summary
      }`,
    ].join("\n");

    /**
     * --------------------------------------------------
     * 4. Relevant Organizational Memory
     * --------------------------------------------------
     *
     * MemoryRecallResult does NOT have `text`.
     *
     * The actual source is:
     *
     * memoryContext.memories
     *
     * Therefore render the retrieved MemoryRecord[]
     * directly into deterministic text.
     */
    const retrievalDiagnostics = memoryContext.retrieval;

const memoryIsTrusted =
  retrieval.confidence_score >= 0.6 &&
  retrieval.retrieval_agreement === true;

const trustedMemories = memoryIsTrusted
  ? memoryContext.memories
  : [];

const memoryLines =
  trustedMemories.map(
    (memory, index) =>
      [
        `Memory ${index + 1}:`,
        `ID: ${memory.id}`,
        `Type: ${memory.type}`,
        `Title: ${memory.title}`,
        `Content: ${memory.content}`,
        `Source: ${memory.source || "unknown"}`,
      ].join("\n"),
  );

const memorySection =
  memoryLines.length > 0
    ? memoryLines.join("\n\n")
    : memoryContext.memories.length > 0
      ? "Relevant organizational memory was found, but it did not pass the retrieval safety gate and was excluded from working context."
      : "No relevant organizational memory found.";
    /**
     * --------------------------------------------------
     * Final Assembly
     * --------------------------------------------------
     */
    return [
      projectSection,

      "",

      retrievalSection,

      "",

      consistencySection,

      "",

      "[RELEVANT ORGANIZATIONAL MEMORY]",

      `Query: ${
        memoryContext.query
      }`,

      `Memory Count: ${
        memoryContext.count
      }`,

      "",

      memorySection,
    ].join("\n");
  }

  /**
   * Keep context assembly bounded.
   *
   * This prevents accidental requests for hundreds
   * of memories from exploding the reasoning context.
   */
  private normalizeLimit(
    limit: number,
  ): number {
    if (!Number.isFinite(limit)) {
      return 5;
    }

    return Math.min(
      Math.max(
        Math.trunc(limit),
        1,
      ),
      20,
    );
  }
}