import type { FastifyInstance } from "fastify";

import { pool } from "../db/postgres.js";
import { requireAuth } from "../middleware/require-auth.js";

import {
  successResponse,
  errorResponse,
} from "../core/api-response.js";

import { MemoryService } from "../memory/memory-service.js";
import { PostgresMemoryRepository } from "../memory/postgres-memory-repository.js";

import { EmbeddingService } from "../embedding/embedding-service.js";
import { PostgresMemoryEmbeddingRepository } from "../embedding/postgres-memory-embedding-repository.js";
import { ProjectStateReader } from "../memory/project-state-reader.js";
import { ProjectStateUpdater } from "../memory/project-state-updater.js";
import { BrainContextAssembler } from "../memory/brain-context-assembler.js";
import { OrganizationalConsistencyChecker } from "../memory/organizational-consistency-checker.js";
import { PudtanReasoningService } from "../memory/pudtan-reasoning-service.js";
import {
  PudtanMemoryService,
} from "../memory/pudtan-memory-service.js";
import {
  PudtanContextService,
} from "../memory/pudtan-context-service.js";
import {
  PudtanContinuityService,
} from "../memory/pudtan-continuity-service.js";

import type {
  PudtanMemoryType,
  PudtanMemoryImportance,
} from "../memory/pudtan-memory-types.js";
import type {
  MemoryImportance,
  MemoryType,
} from "../memory/memory-types.js";

const memoryRepository = new PostgresMemoryRepository();

const embeddingService = new EmbeddingService();

const embeddingRepository =
  new PostgresMemoryEmbeddingRepository();

const memoryService = new MemoryService(
  memoryRepository,
  embeddingService,
  embeddingRepository,
);

const projectStateReader =
  new ProjectStateReader();

const projectStateUpdater =
  new ProjectStateUpdater();

const organizationalConsistencyChecker =
  new OrganizationalConsistencyChecker();

const brainContextAssembler =
  new BrainContextAssembler(
    projectStateReader,
    memoryService,
    organizationalConsistencyChecker,
  );

export const pudtanReasoningService =
  new PudtanReasoningService(
    brainContextAssembler,
  );

export const pudtanMemoryService =
  new PudtanMemoryService();

export const pudtanContextService =
  new PudtanContextService(
    pudtanMemoryService,
    brainContextAssembler,
  );

export const pudtanContinuityService =
  new PudtanContinuityService();
interface CreateMemoryBody {
  content: string;
  source: string;
  type?: MemoryType;
  importance?: MemoryImportance;
  source_id?: string;
  actor_id?: string;
  project_id?: string;
  title?: string;
  category?:
    | "Technical"
    | "Coding"
    | "Architecture"
    | "Development"
    | "AI"
    | "Reference";
  reason?: string;
  impact?: string;
  current_state?: string;
  expected_result?: string;
  blocked_reason?: string;
}

interface MemoryListQuery {
  project_id?: string;
}

interface MemorySearchQuery {
  project_id?: string;
  q?: string;
  limit?: string;
}

interface MemoryRecallBody {
  project_id: string;
  query: string;
  limit?: number;
}

interface PudtanAskBody {
  project_id: string;
  query: string;
  limit?: number;
}
interface PudtanMemoryBody {
  memory_type: PudtanMemoryType;
  title: string;
  content: string;
  summary?: string;
  importance?: PudtanMemoryImportance;
  project_id?: string;
  source?: string;
  metadata?: Record<string, unknown>;
}

interface PudtanMemoryListQuery {
  limit?: string;
}

interface PudtanMemorySearchQuery {
  q?: string;
  limit?: string;
}
interface PudtanContextQuery {
  project_id: string;
  q: string;
  continuity_id?: string;
  limit?: string;
}

interface PudtanContinuityQuery {
  project_id?: string;
  continuity_id?: string;
  limit?: string;
}
export async function registerApiV1Routes(
  app: FastifyInstance,
): Promise<void> 

{
/*
   * Health
   */
  app.get("/api/v1/health", async (request, reply) => {
    try {
      await pool.query("SELECT 1");

      return successResponse(
        {
          service: "kao-brain-api",
          status: "healthy",
          database: "healthy",
        },
        request.context.request_id,
        request.context.trace_id,
      );
    } catch (error) {
      request.log.error(error);

      return reply.status(503).send(
        errorResponse(
          "DATABASE_UNAVAILABLE",
          "Database is unavailable.",
          request.context.request_id,
          request.context.trace_id,
        ),
      );
    }
  });

  /*
   * Create Memory
   */
  app.post<{ Body: CreateMemoryBody }>(
    "/api/v1/memories",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const body = request.body;

        if (!body || typeof body !== "object") {
          return reply.status(400).send(
            errorResponse(
              "INVALID_REQUEST",
              "Request body is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.content !== "string" ||
          body.content.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_CONTENT",
              "content is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.source !== "string" ||
          body.source.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_SOURCE",
              "source is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          body.project_id !== undefined &&
          typeof body.project_id !== "string"
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id must be a string.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          body.type !== undefined &&
          ![
            "conversation",
            "idea",
            "decision",
            "task",
            "knowledge",
            "current_context",
            "deprecated",
          ].includes(body.type)
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_MEMORY_TYPE",
              "Unsupported memory type.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        const result = await memoryService.ingest({
          content: body.content,
          type: body.type ?? "conversation",
          importance: body.importance ?? "normal",
          source: body.source,

          ...(body.source_id !== undefined
            ? { source_id: body.source_id }
            : {}),

          ...(body.actor_id !== undefined
            ? { actor_id: body.actor_id }
            : {}),

          ...(body.project_id !== undefined
            ? { project_id: body.project_id }
            : {}),

          ...(body.title !== undefined
            ? { title: body.title }
            : {}),

          ...(body.category !== undefined
            ? { category: body.category }
            : {}),

          ...(body.reason !== undefined
            ? { reason: body.reason }
            : {}),

          ...(body.impact !== undefined
            ? { impact: body.impact }
            : {}),

          ...(body.current_state !== undefined
            ? { current_state: body.current_state }
            : {}),

          ...(body.expected_result !== undefined
            ? { expected_result: body.expected_result }
            : {}),

          ...(body.blocked_reason !== undefined
            ? { blocked_reason: body.blocked_reason }
            : {}),
        });

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_INGEST_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to ingest memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Search Memories
   *
   * IMPORTANT:
   * This route must be declared before /api/v1/memories/:id
   */
  app.get<{ Querystring: MemorySearchQuery }>(
    "/api/v1/memories/search",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const projectId = request.query.project_id?.trim();
        const query = request.query.q?.trim();

        if (!projectId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (!query) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "q is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 10;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(request.query.limit);

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 50
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 50.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const result = await memoryService.search(
          projectId,
          query,
          limit,
        );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_SEARCH_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to search memories.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Build Memory Context
   *
   * This endpoint is the bridge between
   * memory retrieval and the future AI layer.
   */
  app.get<{ Querystring: MemorySearchQuery }>(
    "/api/v1/memories/context",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const projectId = request.query.project_id?.trim();
        const query = request.query.q?.trim();

        if (!projectId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (!query) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "q is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 5;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(request.query.limit);

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 20
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 20.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const result = await memoryService.buildContext(
          projectId,
          query,
          limit,
        );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_CONTEXT_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to build memory context.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Pudtan Reasoning
   *
   * Question
   *   ↓
   * Project State + Memory Retrieval
   *   ↓
   * Brain Context Assembly
   *   ↓
   * OpenAI Reasoning
   *   ↓
   * Answer + Evidence + Recommendations
   */
  app.post<{ Body: PudtanAskBody }>(
    "/api/v1/pudtan/ask",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const body = request.body;

        if (!body || typeof body !== "object") {
          return reply.status(400).send(
            errorResponse(
              "INVALID_REQUEST",
              "Request body is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.project_id !== "string" ||
          body.project_id.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.query !== "string" ||
          body.query.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "query is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 5;

        if (body.limit !== undefined) {
          if (
            typeof body.limit !== "number" ||
            !Number.isInteger(body.limit) ||
            body.limit < 1 ||
            body.limit > 20
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 20.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = body.limit;
        }

        const result =
          await pudtanReasoningService.reason({
            projectId: body.project_id.trim(),
            query: body.query.trim(),
            limit,
          });

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(
          error,
          "Pudtan reasoning failed.",
        );

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_REASONING_FAILED",
            error instanceof Error
              ? error.message
              : "Pudtan reasoning failed.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Recall
   *
   * Main endpoint for the future AI layer.
   *
   * Question
   *   ↓
   * Recall
   *   ↓
   * Search active memories
   *   ↓
   * Build context
   *   ↓
   * Return AI-ready memory context
   */
  app.post<{ Body: MemoryRecallBody }>(
    "/api/v1/recall",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const body = request.body;

        if (!body || typeof body !== "object") {
          return reply.status(400).send(
            errorResponse(
              "INVALID_REQUEST",
              "Request body is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.project_id !== "string" ||
          body.project_id.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.query !== "string" ||
          body.query.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "query is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 5;

        if (body.limit !== undefined) {
          if (
            typeof body.limit !== "number" ||
            !Number.isInteger(body.limit) ||
            body.limit < 1 ||
            body.limit > 20
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 20.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = body.limit;
        }

        const result = await memoryService.recall(
          body.project_id.trim(),
          body.query.trim(),
          limit,
        );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_RECALL_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to recall memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * List Memories by Project
   */
  app.get<{ Querystring: MemoryListQuery }>(
    "/api/v1/memories",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const projectId = request.query.project_id?.trim();

        if (!projectId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        const memories =
          await memoryRepository.findByProject(projectId);

        return successResponse(
          memories,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_LIST_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to list memories.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Get Memory by ID
   */
  app.get<{ Params: { id: string } }>(
    "/api/v1/memories/:id",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const memory = await memoryRepository.getById(
          request.params.id,
        );

        if (!memory) {
          return reply.status(404).send(
            errorResponse(
              "MEMORY_NOT_FOUND",
              "Memory not found.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        return successResponse(
          memory,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "MEMORY_GET_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to get memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );
  /*
   * Pudtan Memory
   *
   * This memory belongs to Pudtan itself.
   * It is intentionally separate from organizational memory.
   */

  app.post<{ Body: PudtanMemoryBody }>(
    "/api/v1/pudtan/memory",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const body = request.body;

        if (!body || typeof body !== "object") {
          return reply.status(400).send(
            errorResponse(
              "INVALID_REQUEST",
              "Request body is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.memory_type !== "string" ||
          ![
            "identity",
            "session_summary",
            "project_context",
            "decision",
            "task_continuity",
            "important_context",
          ].includes(body.memory_type)
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_MEMORY_TYPE",
              "Unsupported Pudtan memory type.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.title !== "string" ||
          body.title.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_TITLE",
              "title is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          typeof body.content !== "string" ||
          body.content.trim().length === 0
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_CONTENT",
              "content is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          body.importance !== undefined &&
          ![
            "low",
            "normal",
            "high",
            "critical",
          ].includes(body.importance)
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_IMPORTANCE",
              "Unsupported Pudtan memory importance.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (
          body.project_id !== undefined &&
          typeof body.project_id !== "string"
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id must be a string.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        const result =
          await pudtanMemoryService.remember({
            memory_type: body.memory_type,
            title: body.title,
            content: body.content,

            ...(body.summary !== undefined
              ? {
                  summary: body.summary,
                }
              : {}),

            ...(body.importance !== undefined
              ? {
                  importance: body.importance,
                }
              : {}),

            ...(body.project_id !== undefined
              ? {
                  project_id: body.project_id,
                }
              : {}),

            ...(body.source !== undefined
              ? {
                  source: body.source,
                }
              : {}),

            ...(body.metadata !== undefined
              ? {
                  metadata: body.metadata,
                }
              : {}),
          });

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_MEMORY_CREATE_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to create Pudtan memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Get latest Pudtan memories
   */

  app.get<{
    Querystring: PudtanMemoryListQuery;
  }>(
    "/api/v1/pudtan/memory/latest",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        let limit = 20;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(
            request.query.limit,
          );

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 100
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 100.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const result =
          await pudtanMemoryService.getLatest(
            limit,
          );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_MEMORY_LATEST_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to load Pudtan memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Search Pudtan memories
   */

  app.get<{
    Querystring: PudtanMemorySearchQuery;
  }>(
    "/api/v1/pudtan/memory/search",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const query = request.query.q?.trim();

        if (!query) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "q is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 20;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(
            request.query.limit,
          );

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 100
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 100.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const result =
          await pudtanMemoryService.search(
            query,
            limit,
          );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_MEMORY_SEARCH_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to search Pudtan memory.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Get Pudtan Session Continuity
   *
   * Loads Pudtan memories belonging to
   * the same project and continuity chain.
   */

  app.get<{
    Querystring: PudtanContinuityQuery;
  }>(
    "/api/v1/pudtan/continuity",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const projectId =
          request.query.project_id?.trim();

        if (!projectId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        const continuityId =
          request.query.continuity_id?.trim();

        if (!continuityId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_CONTINUITY_ID",
              "continuity_id is required and must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 20;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(
            request.query.limit,
          );

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 20
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 20.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const result =
          await pudtanContinuityService.getContinuity(
            projectId,
            continuityId,
            limit,
          );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_CONTINUITY_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to load Pudtan session continuity.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

  /*
   * Pudtan Working Context
   *
   * Combines Pudtan Memory with
   * KaoSure Organizational Context.
   */

  app.get<{
    Querystring: PudtanContextQuery;
  }>(
    "/api/v1/pudtan/context",
    {
      preHandler: requireAuth,
    },
    async (request, reply) => {
      try {
        const projectId =
          request.query.project_id?.trim();

        const query =
          request.query.q?.trim();

        if (!projectId) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_PROJECT_ID",
              "project_id is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        if (!query) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_QUERY",
              "q is required.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        let limit = 10;

        if (request.query.limit !== undefined) {
          const parsedLimit = Number(
            request.query.limit,
          );

          if (
            !Number.isInteger(parsedLimit) ||
            parsedLimit < 1 ||
            parsedLimit > 20
          ) {
            return reply.status(400).send(
              errorResponse(
                "INVALID_LIMIT",
                "limit must be an integer between 1 and 20.",
                request.context.request_id,
                request.context.trace_id,
              ),
            );
          }

          limit = parsedLimit;
        }

        const continuityId =
          request.query.continuity_id?.trim();

        if (
          request.query.continuity_id !== undefined &&
          !continuityId
        ) {
          return reply.status(400).send(
            errorResponse(
              "INVALID_CONTINUITY_ID",
              "continuity_id must not be empty.",
              request.context.request_id,
              request.context.trace_id,
            ),
          );
        }

        const result =
          await pudtanContextService.buildContext(
            projectId,
            query,
            limit,
            continuityId,
          );

        return successResponse(
          result,
          request.context.request_id,
          request.context.trace_id,
        );
      } catch (error) {
        request.log.error(error);

        return reply.status(500).send(
          errorResponse(
            "PUDTAN_CONTEXT_FAILED",
            error instanceof Error
              ? error.message
              : "Failed to build Pudtan working context.",
            request.context.request_id,
            request.context.trace_id,
          ),
        );
      }
    },
  );

}