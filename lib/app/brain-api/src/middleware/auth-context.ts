import { createRemoteJWKSet, jwtVerify } from "jose";

export type ActorType = "human" | "agent" | "system";

export interface AuthContext {
  authenticated: boolean;
  actor_id: string | null;
  actor_type: ActorType | null;
  issuer: string | null;
  audience: string | null;
  token_expires_at: number | null;
}

const kaoIdIssuer = process.env.KAO_ID_ISSUER;
const kaoIdAudience =
  process.env.KAO_ID_AUDIENCE ?? "kao-brain";
const kaoIdJwksUrl = process.env.KAO_ID_JWKS_URL;

function unauthenticatedContext(): AuthContext {
  return {
    authenticated: false,
    actor_id: null,
    actor_type: null,
    issuer: null,
    audience: null,
    token_expires_at: null,
  };
}

function getBearerToken(
  headers: Record<string, unknown>,
): string | null {
  const authorization = headers.authorization;

  if (typeof authorization !== "string") {
    return null;
  }

  const match = authorization.match(/^Bearer\s+(.+)$/i);

  if (!match) {
    return null;
  }

  return match[1] ?? null;
}

function getActorType(
  value: unknown,
): ActorType | null {
  if (
    value === "human" ||
    value === "agent" ||
    value === "system"
  ) {
    return value;
  }

  return null;
}

/**
 * Kao ID → Kao Brain authentication boundary.
 *
 * Kao ID is the Identity Authority.
 * Kao Brain only verifies the signed Identity Token
 * and establishes the request identity context.
 */
export async function createAuthContext(
  headers: Record<string, unknown>,
): Promise<AuthContext> {
  const token = getBearerToken(headers);

  /**
   * No Authorization header.
   *
   * This is anonymous access, not a token validation failure.
   */
  if (!token) {
    return unauthenticatedContext();
  }

  /**
   * Kao Brain must know who issued the token.
   */
  if (!kaoIdIssuer) {
    throw new Error(
      "Authentication configuration missing: KAO_ID_ISSUER is required.",
    );
  }

  /**
   * Kao Brain must know where to obtain Kao ID's
   * public signing keys.
   */
  if (!kaoIdJwksUrl) {
    throw new Error(
      "Authentication configuration missing: KAO_ID_JWKS_URL is required.",
    );
  }

  try {
    const JWKS = createRemoteJWKSet(
      new URL(kaoIdJwksUrl),
    );

    const result = await jwtVerify(
      token,
      JWKS,
      {
        issuer: kaoIdIssuer,
        audience: kaoIdAudience,
      },
    );

    const payload = result.payload;

    const subject =
      typeof payload.sub === "string"
        ? payload.sub
        : null;

    if (!subject) {
      return unauthenticatedContext();
    }

    const issuer =
      typeof payload.iss === "string"
        ? payload.iss
        : null;

    const audience =
      typeof payload.aud === "string"
        ? payload.aud
        : null;

    const tokenExpiresAt =
      typeof payload.exp === "number"
        ? payload.exp
        : null;

    /**
     * actor_type is intentionally NOT inferred.
     *
     * The current Kao ID ↔ Kao Brain Token Contract
     * does not define an actor_type claim yet.
     *
     * Once the contract officially defines it,
     * it can be read from the token here.
     */
    const actorType = getActorType(
      payload.actor_type,
    );

    return {
      authenticated: true,
      actor_id: subject,
      actor_type: actorType,
      issuer,
      audience,
      token_expires_at: tokenExpiresAt,
    };
  } catch {
    /**
     * Token exists but cannot be verified.
     *
     * Do not trust any identity information from
     * an invalid token.
     */
    return unauthenticatedContext();
  }
}