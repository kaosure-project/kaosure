# Kao ID development plan (R15)

Order of work after the business registration stepper (R15A):

1. Business review queue (R15B) — done.
2. Security Advisor closure — next.
3. Business Staff Management.
4. OpenID Connect + OAuth 2.0 (Authorization Code + PKCE) SSO.

## 1. Business review queue (R15B) — done

- Migration `20261012030000_business_registration_review_r15b.sql`.
- Reviewers: company Owner or `kyc_officer`, fresh MFA when `security_policy_r14a.mfa_required`, two-person rule when `dual_review` (resource `kaoid_business_review`, evidence fingerprint, 24 h expiry).
- Approve: document, organization verification and legal profile approved; Business Kao ID issued in the same transaction. Requires the applicant's active personal Kao ID and verified payout bank.
- Reject: reason (3–1000 chars) shown to the owner; organization, membership and legal profile become inactive so the registration number can be resubmitted.
- Audit: `activity_logs` action `kyc.business.approve|reject` with actor snapshot. Notifications: `business_review_new|second|restart` to reviewers, `business_approved|rejected` to the owner.
- `register_organization` and `initialize_organization_verification` are no longer client-executable.
- Client: `BusinessReviewQueuePage` / `BusinessReviewDetailPage` (admin hub entry), notice routing, reviewer note on the owner's status screen.

## 2. Security Advisor closure — next

- RLS: every exposed table has RLS enabled and explicit policies; `brain_*` and `pudtan_memory` stay server-only.
- SECURITY DEFINER: inventory functions executable by `anon`/`authenticated`; revoke anything not called by clients (`issue_business_kao_id`, `create_business_shop`, legacy approval RPCs); pin `search_path`.
- Extensions installed in `public` moved to `extensions`.
- Leaked password protection and password strength: Supabase Auth setting (dashboard / Management API).
- Audit log coverage for privileged writes; rate limiting on auth-adjacent RPCs.

## 3. Business Staff Management

Goal: a store owner appoints other Kao ID holders as store staff with clear, server-enforced permissions.

### Rules

- Only the store owner (personal store: `shops.owner_id`; business store: the organization's active `authorized_person`/`owner`) invites, changes roles and removes staff.
- Invitee must hold an active, verified personal Kao ID (Authentication ≠ Kao ID). Invitation by Kao ID, never by free-text email.
- Being staff of another store does not count as owning a store (1 account = 1 store still applies to ownership).
- Finance (payouts, bank, escrow, wallet) and closing or transferring the store are owner-only for every role.
- Staff cannot invite, promote or remove staff; a manager cannot change the owner or another manager.

### Roles and permissions

| Permission | Owner | Manager | Staff / Seller |
|---|---|---|---|
| Create, edit, list, unlist products | ✓ | ✓ | ✓ |
| Manage stock | ✓ | ✓ | ✓ |
| Approve / ship / cancel orders | ✓ | ✓ | — |
| View sales reports | ✓ | ✓ | — |
| Store profile and settings | ✓ | ✓ | — |
| Manage staff | ✓ | — | — |
| Finance, payouts, close store | ✓ | — | — |

### Database

- Evolve the existing `public.shop_staff` instead of adding a parallel `store_staff` table:
  - `role` constrained to `manager | staff`; owner is never a `shop_staff` row.
  - Add `status` (`invited | active | suspended | removed`), `invited_at`, `accepted_at`, `removed_at`, `removed_by`.
  - Permissions derived from the role by a server-side matrix (`marketplace_private.store_role_permissions`); the per-row `can_manage_*` booleans are frozen and later dropped to avoid drift.
- Access: RLS enabled, no direct table grants; all writes through `marketplace_private.*` SECURITY DEFINER functions with public invoker wrappers (`store_staff_invite`, `store_staff_accept`, `store_staff_decline`, `store_staff_set_role`, `store_staff_remove`, `store_staff_list`).
- One helper, `marketplace_private.can_store(shop_id, permission)`, used by product, stock, order and report RPCs and RLS policies.
- Each change writes `activity_logs` (`store.staff.invite|accept|role|remove`) and notifies the affected member.
- Limits: max staff per store, invitation expiry (7 days), rate limit on invitations.

### Client (Secondhand, Clean Architecture)

- `domain`: `StoreStaffMember`, `StoreRole`, `StorePermission`, `StoreStaffRepository`.
- `data`: Supabase data source and repository (session-pinned like the review repository), failure mapper.
- `application`: staff list and invitation controllers; permission provider used to hide actions the server would reject.
- `presentation`: staff list, invite by Kao ID, role change, pending invitation inbox for the invitee.

## 4. OpenID Connect + OAuth 2.0 (PKCE) SSO

R1 (`kao_id_secondhand_sso_handoff_r1.md`) shares one Supabase session on a single origin. Target: Kao ID as the identity provider for Secondhand, Auction and future apps on any domain or native platform.

### Target

- Authorization Code flow with PKCE (S256) for every client; no implicit flow, no tokens in URLs.
- Kao ID hosts login, MFA and the consent screen; sub-apps never handle passwords.
- OIDC `id_token` validated by clients (`iss`, `aud`, `exp`, `nonce`) against the published JWKS.
- Claims: `sub`, `email`, `locale` (from `kaosure.app.locale`), and `kao_id_status` so apps can tell an authenticated user from a verified Kao ID holder.

### Phases

1. Decide the provider. Preferred: Supabase Auth OAuth 2.1 server (confirm availability for the project); fallback: a dedicated IdP (e.g. Ory Hydra or Keycloak) federated with Supabase Auth. Move to asymmetric JWT signing keys and a stable issuer domain.
2. Client registry: Secondhand registered as a public client with exact redirect URIs per environment; scopes `openid email profile` plus a Kao ID scope.
3. Kao ID: authorize and consent route, consent records, sign-out and revocation endpoints, audit of grants.
4. Secondhand: PKCE login, `state` and `nonce`, refresh token rotation, sign-out (revoke plus RP-initiated logout), then remove the R1 same-origin handoff.
5. Native apps: App Links / Universal Links redirects, system browser only.
6. Hardening: exact redirect matching, short-lived codes, refresh-token reuse detection, rate limits, session listing and remote sign-out, back-channel logout later.
