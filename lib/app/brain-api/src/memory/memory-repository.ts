import type {
  MemoryInput,
  MemoryRecord,
} from "./memory-types.js";

export interface MemoryRepository {
  create(input: MemoryInput): Promise<MemoryRecord>;

  getById(id: string): Promise<MemoryRecord | null>;

  findByProject(projectId: string): Promise<MemoryRecord[]>;

  search(
    projectId: string,
    query: string,
    limit?: number,
  ): Promise<MemoryRecord[]>;

  findByActor(actorId: string): Promise<MemoryRecord[]>;

  deprecate(id: string): Promise<MemoryRecord | null>;
}