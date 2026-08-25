import "dotenv/config";

import Fastify from "fastify";
import cors from "@fastify/cors";

import {
  localhostHostValidation,
} from "@modelcontextprotocol/fastify";

import {
  NodeStreamableHTTPServerTransport,
} from "@modelcontextprotocol/node";

import { pool } from "./db/postgres.js";

import {
  createRequestContext,
  type RequestContext,
} from "./middleware/request-context.js";

import {
  createAuthContext,
  type AuthContext,
} from "./middleware/auth-context.js";

import {
  requireAuth,
} from "./middleware/require-auth.js";

import { registerApiV1Routes } from "./routes/api-v1.js";

import {
  createPudtanMcpServer,
} from "./mcp/pudtan-mcp.js";


declare module "fastify" {
  interface FastifyRequest {
    context: RequestContext;
    auth: AuthContext;
  }
}

const app = Fastify({
  logger: true,
});


/**
 * ============================================================
 * CORS
 * ============================================================
 *
 * Development:
 * Allow only local Flutter Web origins.
 *
 * This intentionally does NOT use origin: true,
 * because that would reflect arbitrary origins.
 */
await app.register(cors, {
  origin: [
    /^http:\/\/localhost:\d+$/,
    /^http:\/\/127\.0\.0\.1:\d+$/,
  ],
  methods: [
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
    "OPTIONS",
  ],
});


/**
 * ============================================================
 * MCP Host Validation
 * ============================================================
 *
 * Protect localhost MCP endpoint against DNS rebinding.
 *
 * The Fastify MCP adapter provides the validation hook
 * specifically for Fastify applications.
 */
app.addHook(
  "onRequest",
  localhostHostValidation(),
);


/**
 * ============================================================
 * Request Context + Authentication
 * ============================================================
 *
 * Every request receives:
 *
 * - request_id
 * - trace_id
 * - authentication context
 *
 * Kao ID is the Identity Authority.
 * Kao Brain only verifies the Kao ID token.
 */
app.addHook(
  "onRequest",
  async (request) => {
    const headers =
      request.headers as Record<string, unknown>;

    request.context =
      createRequestContext(headers);

    request.auth =
      await createAuthContext(headers);
  },
);


/**
 * ============================================================
 * API Routes
 * ============================================================
 */
await registerApiV1Routes(app);


/**
 * ============================================================
 * MCP — Streamable HTTP
 * ============================================================
 *
 * Architecture:
 *
 * Fastify
 *    ↓
 * /mcp
 *    ↓
 * Authentication
 *    ↓
 * Kao ID JWT verification
 *    ↓
 * NodeStreamableHTTPServerTransport
 *    ↓
 * Pudtan MCP Server
 *    ↓
 * Pudtan Memory / Context / Continuity / Reasoning
 *
 * Stateless transport:
 * sessionIdGenerator: undefined
 *
 * A fresh Pudtan MCP server + transport is created
 * for each HTTP request.
 *
 * Project scope is intentionally NOT accepted
 * from the MCP caller.
 *
 * Pudtan resolves the project from the
 * server-side PUDTAN_PROJECT_ID configuration.
 */
app.route({
  method: [
    "POST",
    "GET",
    "DELETE",
  ],

  url: "/mcp",

  /**
   * ==========================================================
   * Authentication Boundary
   * ==========================================================
   *
   * MCP must never be anonymously accessible.
   *
   * The request must contain a valid Kao ID
   * Bearer token before reaching the MCP server.
   */
  preHandler: requireAuth,

  handler: async (
    request,
    reply,
  ) => {
    const mcpServer =
      createPudtanMcpServer();

    const transport =
      new NodeStreamableHTTPServerTransport({
        sessionIdGenerator: undefined,
      });

    try {
      await mcpServer.connect(
        transport,
      );

      reply.raw.on(
        "close",
        () => {
          void transport.close();
          void mcpServer.close();
        },
      );

      await transport.handleRequest(
        request.raw,
        reply.raw,
        request.body,
      );
    } catch (error) {
      request.log.error(
        {
          err: error,
        },
        "MCP request failed",
      );

      if (!reply.sent) {
        reply
          .status(500)
          .send({
            error:
              "MCP_REQUEST_FAILED",

            message:
              "MCP request could not be processed.",
          });
      }
    }
  },
});


/**
 * ============================================================
 * Legacy Health Check
 * ============================================================
 */
app.get(
  "/health",
  async (request) => {
    return {
      success: true,

      data: {
        service:
          "kao-brain-api",

        status:
          "healthy",
      },

      meta: {
        request_id:
          request.context.request_id,

        trace_id:
          request.context.trace_id,
      },
    };
  },
);


/**
 * ============================================================
 * Database Connection Lifecycle
 * ============================================================
 */
app.addHook(
  "onClose",
  async () => {
    await pool.end();
  },
);


/**
 * ============================================================
 * Server
 * ============================================================
 */
const port =
  Number(
    process.env.PORT ?? 3000,
  );

const host =
  process.env.HOST ??
  "127.0.0.1";


try {
  await app.listen({
    port,
    host,
  });

  app.log.info(
    `Kao Brain API running on ${host}:${port}`,
  );
} catch (error) {
  app.log.error(error);

  await pool.end();

  process.exit(1);
}