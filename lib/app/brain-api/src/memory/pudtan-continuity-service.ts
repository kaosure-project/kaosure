import {
  PudtanMemoryRepository,
} from "./pudtan-memory-repository.js";

import type {
  PudtanMemoryRecord,
} from "./pudtan-memory-types.js";

export interface PudtanContinuityResult {
  continuity_id: string;
  project_id: string;
  memories: PudtanMemoryRecord[];
  count: number;
}

export class PudtanContinuityService {
  constructor(
    private readonly repository =
      new PudtanMemoryRepository(),
  ) {}

  async getContinuity(
    projectId: string,
    continuityId: string,
    limit = 20,
  ): Promise<PudtanContinuityResult> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedContinuityId =
      continuityId.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedContinuityId) {
      throw new Error(
        "continuity_id is required.",
      );
    }

    const normalizedLimit =
      this.normalizeLimit(limit);

    const memories =
      await this.repository.findByContinuityId(
        normalizedProjectId,
        normalizedContinuityId,
        normalizedLimit,
      );

    return {
      continuity_id:
        normalizedContinuityId,
      project_id:
        normalizedProjectId,
      memories,
      count: memories.length,
    };
  }

  private normalizeLimit(
    limit: number,
  ): number {
    if (!Number.isFinite(limit)) {
      return 20;
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