export interface AuthContext {
  authenticated: boolean;
  actor_id: string | null;
  actor_type: "human" | "agent" | "system" | null;
}

export function createAuthContext(
  headers: Record<string, unknown>,
): AuthContext {
  const actorId =
    typeof headers["x-actor-id"] === "string"
      ? headers["x-actor-id"]
      : null;

  const actorType =
    headers["x-actor-type"] === "human" ||
    headers["x-actor-type"] === "agent" ||
    headers["x-actor-type"] === "system"
      ? headers["x-actor-type"]
      : null;

  return {
    authenticated: actorId !== null,
    actor_id: actorId,
    actor_type: actorType,
  };
}