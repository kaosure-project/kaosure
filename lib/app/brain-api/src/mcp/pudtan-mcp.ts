import { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod/v4";

import {
  pudtanContextService,
  pudtanContinuityService,
  pudtanMemoryService,
  pudtanReasoningService,
} from "../routes/api-v1.js";

const MAX_QUERY_LENGTH = 2000;
const MAX_MEMORY_TITLE_LENGTH = 300;
const MAX_MEMORY_CONTENT_LENGTH = 20000;

const memoryTypes = [
  "identity",
  "session_summary",
  "project_context",
  "decision",
  "task_continuity",
  "important_context",
] as const;

const memoryImportance = [
  "low",
  "normal",
  "high",
  "critical",
] as const;

function getProjectId(): string {
  const value =
    process.env.PUDTAN_PROJECT_ID?.trim();

  if (!value) {
    throw new Error(
      "PUDTAN_PROJECT_ID is required for the Pudtan MCP interface.",
    );
  }

  return value;
}

function cleanQuery(value: string): string {
  const query = value.trim();

  if (!query) {
    throw new Error(
      "query must not be empty.",
    );
  }

  if (query.length > MAX_QUERY_LENGTH) {
    throw new Error(
      `query exceeds ${MAX_QUERY_LENGTH} characters.`,
    );
  }

  return query;
}

function cleanLimit(
  value: number | undefined,
  maximum: number,
): number {
  const limit = value ?? 20;

  if (
    !Number.isInteger(limit) ||
    limit < 1 ||
    limit > maximum
  ) {
    throw new Error(
      `limit must be an integer between 1 and ${maximum}.`,
    );
  }

  return limit;
}

function textResult(data: unknown) {
  return {
    content: [
      {
        type: "text" as const,
        text: JSON.stringify(data),
      },
    ],
  };
}

export function createPudtanMcpServer(): McpServer {
  const server = new McpServer({
    name: "pudtan-brain",
    version: "1.0.0",
  });

  /*
   * ============================================================
   * READ — Latest Memory
   * ============================================================
   *
   * PudtanMemoryService.getLatest() ในระบบปัจจุบัน
   * ยังไม่ได้รับ projectId โดยตรง
   *
   * ดังนั้น MCP จะ:
   *
   * 1. ดึงชุดข้อมูลสูงสุดที่ service รองรับ
   * 2. filter ด้วย PUDTAN_PROJECT_ID ฝั่ง server
   * 3. ส่งกลับเฉพาะ memory ของ project นี้
   *
   * ห้ามให้ MCP caller ส่ง project_id เข้ามาเอง
   * ============================================================
   */

  server.registerTool(
    "pudtan_memory_latest",
    {
      description:
        "Retrieve the latest active Pudtan memories for the configured project.",
      inputSchema: z.object({
        limit: z
          .number()
          .int()
          .min(1)
          .max(100)
          .optional(),
      }),
    },
    async ({ limit }) => {
      const projectId =
        getProjectId();

      const safeLimit =
        cleanLimit(limit, 100);

      /*
       * getLatest() รองรับ limit สูงสุด 100
       * จึงดึง 100 เพื่อให้ project filtering
       * ไม่ทำให้ memory ของ project นี้หายไปเพราะ
       * project อื่นอยู่ในรายการล่าสุด
       */
      const result =
        await pudtanMemoryService.getLatest(
          100,
        );

      const memories =
        result
          .filter(
            (memory) =>
              memory.project_id === projectId,
          )
          .slice(0, safeLimit);

      return textResult({
        project_id: projectId,
        count: memories.length,
        memories,
      });
    },
  );

  /*
   * ============================================================
   * READ — Memory Search
   * ============================================================
   */

  server.registerTool(
    "pudtan_memory_search",
    {
      description:
        "Search active Pudtan memories for the configured project.",
      inputSchema: z.object({
        query: z
          .string()
          .min(1)
          .max(MAX_QUERY_LENGTH),

        limit: z
          .number()
          .int()
          .min(1)
          .max(100)
          .optional(),
      }),
    },
    async ({ query, limit }) => {
      const projectId =
        getProjectId();

      const safeQuery =
        cleanQuery(query);

      const safeLimit =
        cleanLimit(limit, 100);

      /*
       * Search service ปัจจุบันยังไม่ได้รับ projectId
       * จึง filter ผลลัพธ์ก่อนส่งออก MCP
       */
      const result =
        await pudtanMemoryService.search(
          safeQuery,
          100,
        );

      const memories =
        result
          .filter(
            (memory) =>
              memory.project_id === projectId,
          )
          .slice(0, safeLimit);

      return textResult({
        project_id: projectId,
        query: safeQuery,
        count: memories.length,
        memories,
      });
    },
  );

  /*
   * ============================================================
   * READ — Pudtan Working Context
   * ============================================================
   *
   * ใช้ method จริงของ PudtanContextService:
   *
   * buildContext(
   *   projectId,
   *   query,
   *   limit,
   *   continuityId,
   * )
   *
   * ============================================================
   */

  server.registerTool(
    "pudtan_context",
    {
      description:
        "Build Pudtan Working Context from Pudtan Memory and KaoSure Organizational Context.",
      inputSchema: z.object({
        query: z
          .string()
          .min(1)
          .max(MAX_QUERY_LENGTH),

        continuity_id: z
          .string()
          .uuid()
          .optional(),

        limit: z
          .number()
          .int()
          .min(1)
          .max(20)
          .optional(),
      }),
    },
    async ({
      query,
      continuity_id,
      limit,
    }) => {
      const projectId =
        getProjectId();

      const safeQuery =
        cleanQuery(query);

      const safeLimit =
        cleanLimit(limit, 20);

      const result =
        await pudtanContextService.buildContext(
          projectId,
          safeQuery,
          safeLimit,
          continuity_id,
        );

      return textResult(result);
    },
  );

  /*
   * ============================================================
   * READ — Session Continuity
   * ============================================================
   */

  server.registerTool(
    "pudtan_continuity",
    {
      description:
        "Retrieve Pudtan memories belonging to the configured project and a specific session continuity chain.",
      inputSchema: z.object({
        continuity_id:
          z.string().uuid(),

        limit: z
          .number()
          .int()
          .min(1)
          .max(20)
          .optional(),
      }),
    },
    async ({
      continuity_id,
      limit,
    }) => {
      const projectId =
        getProjectId();

      const safeLimit =
        cleanLimit(limit, 20);

      const result =
        await pudtanContinuityService.getContinuity(
          projectId,
          continuity_id,
          safeLimit,
        );

      return textResult(result);
    },
  );

  /*
   * ============================================================
   * REASONING
   * ============================================================
   *
   * ใช้ PudtanReasoningService เดิม
   * ไม่สร้าง reasoning engine ใหม่
   *
   * Organizational State + Memory + Confidence Gate
   * ยังคงอยู่ใน service เดิม
   * ============================================================
   */

  server.registerTool(
    "pudtan_ask",
    {
      description:
        "Ask Pudtan to reason using the existing Organizational State, Memory, Context and deterministic confidence gate.",
      inputSchema: z.object({
        query: z
          .string()
          .min(1)
          .max(MAX_QUERY_LENGTH),

        limit: z
          .number()
          .int()
          .min(1)
          .max(20)
          .optional(),
      }),
    },
    async ({ query, limit }) => {
      const projectId =
        getProjectId();

      const safeQuery =
        cleanQuery(query);

      const safeLimit =
        cleanLimit(limit, 20);

      const result =
        await pudtanReasoningService.reason({
          projectId,
          query: safeQuery,
          limit: safeLimit,
        });

      return textResult(result);
    },
  );

  /*
   * ============================================================
   * WRITE — Remember
   * ============================================================
   *
   * Security rule:
   *
   * MCP caller ห้ามส่ง project_id
   *
   * project_id ถูกกำหนดจาก:
   *
   * PUDTAN_PROJECT_ID
   *
   * ฝั่ง server เท่านั้น
   *
   * ============================================================
   */

  server.registerTool(
    "pudtan_memory_remember",
    {
      description:
        "Store a user-approved fact, decision, task continuity or important context in Pudtan Memory for the configured project.",
      inputSchema: z.object({
        memory_type:
          z.enum(memoryTypes),

        title: z
          .string()
          .min(1)
          .max(
            MAX_MEMORY_TITLE_LENGTH,
          ),

        content: z
          .string()
          .min(1)
          .max(
            MAX_MEMORY_CONTENT_LENGTH,
          ),

        summary: z
          .string()
          .max(2000)
          .optional(),

        importance: z
          .enum(memoryImportance)
          .optional(),

        source: z
          .string()
          .max(200)
          .optional(),

        metadata: z
          .record(
            z.string(),
            z.unknown(),
          )
          .optional(),
      }),
    },
    async ({
      memory_type,
      title,
      content,
      summary,
      importance,
      source,
      metadata,
    }) => {
      const projectId =
        getProjectId();

      const safeTitle =
        title.trim();

      const safeContent =
        content.trim();

      if (!safeTitle) {
        throw new Error(
          "title must not be empty.",
        );
      }

      if (!safeContent) {
        throw new Error(
          "content must not be empty.",
        );
      }

      const result =
        await pudtanMemoryService.remember({
          memory_type,
          title: safeTitle,
          content: safeContent,

          ...(summary !== undefined
            ? {
                summary:
                  summary.trim(),
              }
            : {}),

          ...(importance !== undefined
            ? {
                importance,
              }
            : {}),

          project_id: projectId,

          source:
            source?.trim() ||
            "chatgpt-mcp",

          ...(metadata !== undefined
            ? {
                metadata,
              }
            : {}),
        });

      return textResult({
        saved: true,
        project_id: projectId,
        memory: result,
      });
    },
  );

  return server;
}