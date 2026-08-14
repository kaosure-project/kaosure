import "dotenv/config";

import Fastify from "fastify";
import cors from "@fastify/cors";

import { pool } from "./db/postgres.js";

import {
  createRequestContext,
  type RequestContext,
} from "./middleware/request-context.js";

import {
  createAuthContext,
  type AuthContext,
} from "./middleware/auth-context.js";

import { registerApiV1Routes } from "./routes/api-v1.js";

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
 * CORS
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
 * Request Context
 */
app.addHook("onRequest", async (request) => {
  const headers = request.headers as Record<string, unknown>;

  request.context = createRequestContext(headers);
  request.auth = createAuthContext(headers);
});

/**
 * API Routes
 */
await registerApiV1Routes(app);

/**
 * Legacy Health Check
 */
app.get("/health", async (request) => {
  return {
    success: true,
    data: {
      service: "kao-brain-api",
      status: "healthy",
    },
    meta: {
      request_id: request.context.request_id,
      trace_id: request.context.trace_id,
    },
  };
});

/**
 * Database Connection Lifecycle
 */
app.addHook("onClose", async () => {
  await pool.end();
});

/**
 * Server
 */
const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "127.0.0.1";

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