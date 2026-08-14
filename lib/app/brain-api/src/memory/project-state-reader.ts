import { pool } from "../db/postgres.js";

export interface ProjectState {
  project: {
    id: string;
    name: string;
    slug: string;
    description: string | null;
    status: string;
  };

  context: {
    current_phase: string | null;
    current_focus: string | null;
    current_objective: string | null;
    current_progress: string | null;
    current_blockers: string | null;
    current_priority: string | null;
    next_step: string | null;
    updated_at: string;
  } | null;

  memory_counts: {
    knowledge: number;
    idea: number;
    decision: number;
    task: number;
  };
}

type ProjectRow = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  status: string;
};

type ContextRow = {
  current_phase: string | null;
  current_focus: string | null;
  current_objective: string | null;
  current_progress: string | null;
  current_blockers: string | null;
  current_priority: string | null;
  next_step: string | null;
  updated_at: string;
};

type CountRow = {
  memory_type: string;
  count: number;
};

export class ProjectStateReader {
  async getProjectState(
    projectId: string,
  ): Promise<ProjectState> {
    const normalizedProjectId = projectId.trim();

    if (!normalizedProjectId) {
      throw new Error("project_id is required.");
    }

    const projectResult =
      await pool.query<ProjectRow>(
        `
          SELECT
            id,
            name,
            slug,
            description,
            status
          FROM public.brain_projects
          WHERE id = $1
          LIMIT 1
        `,
        [normalizedProjectId],
      );

    const project = projectResult.rows[0];

    if (!project) {
      throw new Error(
        `Project not found: ${normalizedProjectId}`,
      );
    }

    const contextResult =
      await pool.query<ContextRow>(
        `
          SELECT
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
        [normalizedProjectId],
      );

    const context =
      contextResult.rows[0] ?? null;

    const countResult =
      await pool.query<CountRow>(
        `
          SELECT
            memory_type,
            COUNT(*)::int AS count
          FROM (
            SELECT
              'knowledge'::text AS memory_type
            FROM public.brain_knowledge
            WHERE project_id = $1
              AND status = 'active'

            UNION ALL

            SELECT
              'idea'::text AS memory_type
            FROM public.brain_ideas
            WHERE project_id = $1
              AND status = 'New'

            UNION ALL

            SELECT
              'decision'::text AS memory_type
            FROM public.brain_decisions
            WHERE project_id = $1
              AND status = 'Proposed'

            UNION ALL

            SELECT
              'task'::text AS memory_type
            FROM public.brain_tasks
            WHERE project_id = $1
              AND status = 'TODO'
          ) AS memories
          GROUP BY memory_type
          ORDER BY memory_type
        `,
        [normalizedProjectId],
      );

    const memoryCounts = {
      knowledge: 0,
      idea: 0,
      decision: 0,
      task: 0,
    };

    for (const row of countResult.rows) {
      if (
        row.memory_type === "knowledge" ||
        row.memory_type === "idea" ||
        row.memory_type === "decision" ||
        row.memory_type === "task"
      ) {
        memoryCounts[row.memory_type] =
          Number(row.count);
      }
    }

    return {
      project: {
        id: project.id,
        name: project.name,
        slug: project.slug,
        description: project.description,
        status: project.status,
      },

      context: context
        ? {
            current_phase:
              context.current_phase,
            current_focus:
              context.current_focus,
            current_objective:
              context.current_objective,
            current_progress:
              context.current_progress,
            current_blockers:
              context.current_blockers,
            current_priority:
              context.current_priority,
            next_step:
              context.next_step,
            updated_at:
              context.updated_at,
          }
        : null,

      memory_counts: memoryCounts,
    };
  }
}
