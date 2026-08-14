import {
  PudtanMemoryRepository,
} from "./pudtan-memory-repository.js";

import type {
  PudtanMemoryInput,
  PudtanMemoryRecord,
} from "./pudtan-memory-types.js";

export class PudtanMemoryService {
  constructor(
    private readonly repository =
      new PudtanMemoryRepository(),
  ) {}

  async remember(
    input: PudtanMemoryInput,
  ): Promise<PudtanMemoryRecord> {
    const title = input.title.trim();
    const content = input.content.trim();

    if (!title) {
      throw new Error(
        "Pudtan memory title is required.",
      );
    }

    if (!content) {
      throw new Error(
        "Pudtan memory content is required.",
      );
    }

    const normalizedInput: PudtanMemoryInput = {
      ...input,
      title,
      content,
    };

    const summary = input.summary?.trim();

    if (summary) {
      normalizedInput.summary = summary;
    }

    return this.repository.create(
      normalizedInput,
    );
  }

  async getLatest(
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    return this.repository.getLatest(limit);
  }

  async getLatestByProject(
    projectId: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    const normalizedProjectId =
      projectId.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    return this.repository.getLatestByProject(
      normalizedProjectId,
      limit,
    );
  }

  async search(
    query: string,
    limit = 20,
  ): Promise<PudtanMemoryRecord[]> {
    return this.repository.search(
      query,
      limit,
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

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedQuery) {
      return [];
    }

    return this.repository.searchByProject(
      normalizedProjectId,
      normalizedQuery,
      limit,
    );
  }

  async getById(
    id: string,
  ): Promise<PudtanMemoryRecord | null> {
    return this.repository.getById(id);
  }

  async getByIdInProject(
    projectId: string,
    id: string,
  ): Promise<PudtanMemoryRecord | null> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedId = id.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedId) {
      return null;
    }

    return this.repository.getByIdInProject(
      normalizedProjectId,
      normalizedId,
    );
  }
}