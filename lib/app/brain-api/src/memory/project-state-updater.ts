import { pool } from "../db/postgres.js";

export interface ProjectStateUpdate {
  current_phase?: string;
  current_focus?: string;
  current_objective?: string;
  current_progress?: string;
  current_blockers?: string;
  current_priority?: string;
  next_step?: string;
}

export interface ProjectMemoryCounts {
  knowledge: number;
  idea: number;
  decision: number;
  task: number;
}

export interface ProjectStateSyncResult {
  project_id: string;
  memory_counts: ProjectMemoryCounts;
  context: {
    id: string;
    current_phase: string | null;
    current_focus: string | null;
    current_objective: string | null;
    current_progress: string | null;
    current_blockers: string | null;
    current_priority: string | null;
    next_step: string | null;
    updated_at: string;
  };
}

const STALE_BLOCKER =
  "ยังไม่มีข้อมูล Idea, Decision และ Task ขององค์กรที่เป็นข้อมูลจริงในระบบ";

export class ProjectStateUpdater {
  async update(
    projectId: string,
    patch: ProjectStateUpdate,
  ): Promise<ProjectStateSyncResult> {
    const normalizedProjectId = projectId.trim();

    if (!normalizedProjectId) {
      throw new Error("project_id is required.");
    }

    const current =
      await this.getContext(normalizedProjectId);

    if (!current) {
      throw new Error(
        `Organizational context not found for project: ${normalizedProjectId}`,
      );
    }

    const counts =
      await this.getMemoryCounts(
        normalizedProjectId,
      );

    const nextBlockers =
      this.removeStaleBlocker(
        patch.current_blockers ??
          current.current_blockers,
        counts,
      );

    const result = await pool.query(
      `
        UPDATE public.brain_contexts
        SET
          current_phase = $2,
          current_focus = $3,
          current_objective = $4,
          current_progress = $5,
          current_blockers = $6,
          current_priority = $7,
          next_step = $8,
          updated_at = now()
        WHERE project_id = $1
        RETURNING
          id,
          current_phase,
          current_focus,
          current_objective,
          current_progress,
          current_blockers,
          current_priority,
          next_step,
          updated_at
      `,
      [
        normalizedProjectId,
        patch.current_phase ??
          current.current_phase,
        patch.current_focus ??
          current.current_focus,
        patch.current_objective ??
          current.current_objective,
        patch.current_progress ??
          current.current_progress,
        nextBlockers,
        patch.current_priority ??
          current.current_priority,
        patch.next_step ??
          current.next_step,
      ],
    );

    return {
      project_id: normalizedProjectId,
      memory_counts: counts,
      context: result.rows[0],
    };
  }

  async syncMemoryState(
    projectId: string,
  ): Promise<ProjectStateSyncResult> {
    const normalizedProjectId =
      projectId.trim();

    if (!normalizedProjectId) {
      throw new Error("project_id is required.");
    }

    const current =
      await this.getContext(
        normalizedProjectId,
      );

    if (!current) {
      throw new Error(
        `Organizational context not found for project: ${normalizedProjectId}`,
      );
    }

    const counts =
      await this.getMemoryCounts(
        normalizedProjectId,
      );

    const nextBlockers =
      this.removeStaleBlocker(
        current.current_blockers,
        counts,
      );

    const result = await pool.query(
      `
        UPDATE public.brain_contexts
        SET
          current_blockers = $2,
          updated_at = now()
        WHERE project_id = $1
        RETURNING
          id,
          current_phase,
          current_focus,
          current_objective,
          current_progress,
          current_blockers,
          current_priority,
          next_step,
          updated_at
      `,
      [
        normalizedProjectId,
        nextBlockers,
      ],
    );

    return {
      project_id: normalizedProjectId,
      memory_counts: counts,
      context: result.rows[0],
    };
  }

  private async getContext(
    projectId: string,
  ) {
    const result = await pool.query(
      `
        SELECT
          id,
          current_phase,
          current_focus,
          current_objective,
          current_progress,
          current_blockers,
          current_priority,
          next_step,
          updated_at
        FROM public.brain_contexts
        WHERE project_id = $1
        LIMIT 1
      `,
      [projectId],
    );

    return result.rows[0] ?? null;
  }

  private async getMemoryCounts(
    projectId: string,
  ): Promise<ProjectMemoryCounts> {
    const result = await pool.query(
      `
        SELECT
          (
            SELECT count(*)::int
            FROM public.brain_knowledge
            WHERE project_id = $1
              AND status = 'active'
          ) AS knowledge,

          (
            SELECT count(*)::int
            FROM public.brain_ideas
            WHERE project_id = $1
              AND status = 'New'
          ) AS idea,

          (
            SELECT count(*)::int
            FROM public.brain_decisions
            WHERE project_id = $1
              AND status = 'Proposed'
          ) AS decision,

          (
            SELECT count(*)::int
            FROM public.brain_tasks
            WHERE project_id = $1
              AND status = 'TODO'
          ) AS task
      `,
      [projectId],
    );

    const row = result.rows[0];

    return {
      knowledge: Number(row.knowledge ?? 0),
      idea: Number(row.idea ?? 0),
      decision: Number(row.decision ?? 0),
      task: Number(row.task ?? 0),
    };
  }

  private removeStaleBlocker(
    blockers: string | null | undefined,
    counts: ProjectMemoryCounts,
  ): string {
    const lines =
      (blockers ?? "")
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);

    const filtered = lines.filter(
      (line) => {
        if (
          line === STALE_BLOCKER &&
          counts.idea > 0 &&
          counts.decision > 0 &&
          counts.task > 0
        ) {
          return false;
        }

        return true;
      },
    );

    return filtered.join("\n");
  }
}