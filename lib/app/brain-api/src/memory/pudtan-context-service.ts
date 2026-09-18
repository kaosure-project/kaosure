import {
  PudtanMemoryService,
} from "./pudtan-memory-service.js";

import {
  PudtanContinuityService,
  type PudtanContinuityResult,
} from "./pudtan-continuity-service.js";

import {
  BrainContextAssembler,
  type BrainContextAssembly,
} from "./brain-context-assembler.js";

import type {
  PudtanMemoryRecord,
} from "./pudtan-memory-types.js";

export interface PudtanContext {
  query: string;
  project_id: string;

  continuity_id?: string;

  pudtan_memory: {
    memories: PudtanMemoryRecord[];
    count: number;
  };

  session_continuity?: {
    memories: PudtanMemoryRecord[];
    count: number;
  };

  organizational_context:
    BrainContextAssembly;

  working_context: string;
}

export class PudtanContextService {
  constructor(
    private readonly pudtanMemoryService =
      new PudtanMemoryService(),

    private readonly brainContextAssembler:
      BrainContextAssembler,

    private readonly pudtanContinuityService =
      new PudtanContinuityService(),
  ) {}

  async buildContext(
    projectId: string,
    query: string,
    limit = 10,
    continuityId?: string,
  ): Promise<PudtanContext> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedQuery =
      query.trim();

    const normalizedContinuityId =
      continuityId?.trim();

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

    if (
      continuityId !== undefined &&
      !normalizedContinuityId
    ) {
      throw new Error(
        "continuity_id must not be empty.",
      );
    }

    const normalizedLimit =
      this.normalizeLimit(limit);

    const [
      organizationalContext,
      latestMemories,
      searchedMemories,
      sessionContinuity,
    ] = await Promise.all([
      this.brainContextAssembler.assemble(
        normalizedProjectId,
        normalizedQuery,
        Math.min(
          normalizedLimit,
          20,
        ),
      ),

      this.pudtanMemoryService.getLatestByProject(
        normalizedProjectId,
        normalizedLimit,
      ),

      this.pudtanMemoryService.searchByProject(
        normalizedProjectId,
        normalizedQuery,
        normalizedLimit,
      ),

      normalizedContinuityId
        ? this.pudtanContinuityService.getContinuity(
            normalizedProjectId,
            normalizedContinuityId,
            normalizedLimit,
          )
        : Promise.resolve(
            undefined,
          ),
    ]);

    const memories =
      this.mergeMemories(
        searchedMemories,
        latestMemories,
        normalizedLimit,
      );

    const workingContext =
      this.buildWorkingContext(
        normalizedQuery,
        memories,
        organizationalContext,
        sessionContinuity,
      );

    const result: PudtanContext = {
      query: normalizedQuery,
      project_id: normalizedProjectId,

      pudtan_memory: {
        memories,
        count: memories.length,
      },

      organizational_context:
        organizationalContext,

      working_context:
        workingContext,
    };

    if (normalizedContinuityId) {
      result.continuity_id =
        normalizedContinuityId;

      result.session_continuity = {
        memories:
          sessionContinuity?.memories ?? [],
        count:
          sessionContinuity?.count ?? 0,
      };
    }

    return result;
  }

  private mergeMemories(
    searched: PudtanMemoryRecord[],
    latest: PudtanMemoryRecord[],
    limit: number,
  ): PudtanMemoryRecord[] {
    const byId =
      new Map<
        string,
        PudtanMemoryRecord
      >();

    for (const memory of searched) {
      byId.set(
        memory.id,
        memory,
      );
    }

    for (const memory of latest) {
      if (!byId.has(memory.id)) {
        byId.set(
          memory.id,
          memory,
        );
      }
    }

    return Array.from(
      byId.values(),
    ).slice(0, limit);
  }

  private buildWorkingContext(
    query: string,
    pudtanMemories:
      PudtanMemoryRecord[],
    organizationalContext:
      BrainContextAssembly,
    sessionContinuity?:
      PudtanContinuityResult,
  ): string {
    const pudtanMemorySection =
      pudtanMemories.length > 0
        ? pudtanMemories
            .map(
              (
                memory,
                index,
              ) =>
                [
                  `Memory ${index + 1}:`,
                  `ID: ${memory.id}`,
                  `Type: ${memory.memory_type}`,
                  `Title: ${memory.title}`,
                  `Content: ${memory.content}`,
                  `Summary: ${
                    memory.summary ??
                    "none"
                  }`,
                  `Importance: ${memory.importance}`,
                  `Source: ${memory.source}`,
                ].join("\n"),
            )
            .join("\n\n")
        : "No Pudtan memory found.";

    const sessionContinuitySection =
      sessionContinuity &&
      sessionContinuity.memories
        .length > 0
        ? sessionContinuity.memories
            .map(
              (
                memory,
                index,
              ) =>
                [
                  `Continuity Memory ${
                    index + 1
                  }:`,
                  `ID: ${memory.id}`,
                  `Type: ${memory.memory_type}`,
                  `Title: ${memory.title}`,
                  `Content: ${memory.content}`,
                  `Summary: ${
                    memory.summary ??
                    "none"
                  }`,
                  `Importance: ${memory.importance}`,
                  `Source: ${memory.source}`,
                  `Sequence: ${
                    this.getContinuitySequence(
                      memory,
                    )
                  }`,
                ].join("\n"),
            )
            .join("\n\n")
        : "No session continuity found.";

    const sections = [
      "[PUDTAN WORKING CONTEXT]",

      `Query: ${query}`,

      "",

      "[PUDTAN MEMORY]",

      `Memory Count: ${
        pudtanMemories.length
      }`,

      "",

      pudtanMemorySection,

      "",

      "[SESSION CONTINUITY]",

      `Continuity ID: ${
        sessionContinuity
          ?.continuity_id ??
        "none"
      }`,

      `Continuity Memory Count: ${
        sessionContinuity?.count ??
        0
      }`,

      "",

      sessionContinuitySection,

      "",

      "[KAOSURE ORGANIZATIONAL CONTEXT]",

      organizationalContext.assembled_text,

      "",

      "[END PUDTAN WORKING CONTEXT]",
    ];

    return sections.join("\n");
  }

  private getContinuitySequence(
    memory: PudtanMemoryRecord,
  ): string {
    const sequence =
      memory.metadata?.sequence;

    if (
      typeof sequence ===
        "number" ||
      typeof sequence ===
        "string"
    ) {
      return String(sequence);
    }

    return "unknown";
  }

  private normalizeLimit(
    limit: number,
  ): number {
    if (!Number.isFinite(limit)) {
      return 10;
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