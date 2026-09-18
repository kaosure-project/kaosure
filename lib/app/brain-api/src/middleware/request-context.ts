import { randomUUID } from "node:crypto";

export type ActorType = "human" | "agent" | "system";

export interface RequestContext {
  actor_id: string | null;
  actor_type: ActorType | null;
  agent_id: string | null;
  request_id: string;
  trace_id: string;
  timestamp: string;
}

export function createRequestContext(
  headers: Record<string, unknown>,
): RequestContext {
  const requestId =
    typeof headers["x-request-id"] === "string"
      ? headers["x-request-id"]
      : randomUUID();

  const traceId =
    typeof headers["x-trace-id"] === "string"
      ? headers["x-trace-id"]
      : randomUUID();

  return {
    actor_id:
      typeof headers["x-actor-id"] === "string"
        ? headers["x-actor-id"]
        : null,

    actor_type:
      headers["x-actor-type"] === "human" ||
      headers["x-actor-type"] === "agent" ||
      headers["x-actor-type"] === "system"
        ? headers["x-actor-type"]
        : null,

    agent_id:
      typeof headers["x-agent-id"] === "string"
        ? headers["x-agent-id"]
        : null,

    request_id: requestId,
    trace_id: traceId,
    timestamp: new Date().toISOString(),
  };
}