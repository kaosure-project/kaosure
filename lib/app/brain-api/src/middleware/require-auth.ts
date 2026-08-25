import type { FastifyReply, FastifyRequest } from "fastify";

import { errorResponse } from "../core/api-response.js";

export async function requireAuth(
  request: FastifyRequest,
  reply: FastifyReply,
): Promise<void> {
  if (request.auth.authenticated) {
    return;
  }

  reply.status(401).send(
    errorResponse(
      "UNAUTHENTICATED",
      "Authentication is required.",
      request.context.request_id,
      request.context.trace_id,
    ),
  );
}