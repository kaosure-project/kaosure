# Kao ID SSO integration guide R18

How a sub-app (Secondhand Web first, Auction and others later) signs members in with Kao ID and reads their live status. This replaces the same-origin handoff in `kao_id_secondhand_sso_handoff_r1.md` for apps on their own domain.

## 1. How it fits together

| Piece | Owner | What it does |
|---|---|---|
| Supabase Auth OAuth 2.1 server | Supabase | Authorization Code + PKCE, refresh tokens, OIDC `id_token` signed with the project's ES256 key, JWKS, discovery |
| `/oauth/consent` page | Kao ID app | Shows the app, scopes and Kao ID claims; member allows or denies |
| `kaoid_private.app_clients_r18` | Kao ID DB | Which OAuth clients may act for members, which claims they read, which RPCs/tables their tokens reach |
| Request guard in `pre_request_r10d` | Kao ID DB | Tokens with a `client_id` claim reach only `kao_id_claims_r18`, `account_access_r10d` and their allow-list; Kao ID admin, KYC and security names are always refused |
| `kao_id_claims_r18()` | Kao ID DB | Live profile, verification, business and role status for the token's member |
| Connected apps page | Kao ID app | Member sees and disconnects apps (Security › Connected apps) |
| Registry page | Kao ID app | Company owner registers, edits and suspends apps (Admin Center › Partners) |

```
Secondhand                         Supabase Auth (issuer)                Kao ID app
    | 1. /oauth/authorize?...PKCE ---->|                                      |
    |                                  | 2. 302 → {SITE_URL}/oauth/consent?authorization_id=…
    |                                  |------------------------------------->| login if needed,
    |                                  |                                      | show consent
    |                                  |<-- 3. approve (member's session) ----|
    | 4. 302 redirect_uri?code&state <-|                                      |
    | 5. POST /oauth/token (code + verifier) -> access, refresh, id_token     |
    | 6. PostgREST with access token: rpc kao_id_claims_r18, allow-listed RPC/tables
```

Issuer: `https://dyfpzmhalfmykvxjdcoq.supabase.co/auth/v1`
Discovery: `{issuer}/.well-known/openid-configuration` (authorize `/oauth/authorize`, token `/oauth/token`, userinfo `/oauth/userinfo`, JWKS `/.well-known/jwks.json`).
Supported scopes: `openid email profile phone`; Secondhand requests `openid email profile` and reads phone verification from `kao_id_claims_r18`. PKCE `S256` is mandatory for public clients.

## 2. One-time setup (Supabase Dashboard + Kao ID)

1. **Enable the OAuth server** — Dashboard › Authentication › OAuth Server: enable, authorization path `/oauth/consent`. Site URL must be the Kao ID web app (dev: `http://localhost:<kao-id-port>`).
2. **Create the client** — Dashboard › Authentication › OAuth Apps › Add: name `Kao Secondhand`, type **Public** (no secret; browser apps cannot keep one), redirect URI `http://localhost:7357/auth/callback` for development. Copy the client ID.
3. **Register it in Kao ID** — Admin Center › Partners › Apps signing in with Kao ID › Register app (company owner, MFA when the policy is on):
   - App code `secondhand_web`, the client ID, name `Kao Secondhand`, Kao app on.
   - Claims: profile, verification, business.
   - Entries are `schema.name` (a bare name means `public`). Tables are read-only unless the entry ends with `:write`; functions have no `:write`.
   - Functions: `public.get_my_seller_readiness`, `public.create_personal_shop`, `public.create_marketplace_listing`.
   - Read-only tables: `public.products`, `public.product_images`, `public.categories`, `public.shops`, `public.banners`, `public.orders`, `public.recommendation_scores`, `public.profiles`, `public.wallets`, `public.wallet_transactions`.
   - Writable tables: `public.favorites:write`, `public.followers:write`, `public.notifications:write`, `public.recently_viewed:write`.
   - App schema (R19b, exposed in API settings): `secondhand.member_profiles:write` and the function `secondhand.ensure_member_profile`. The market profile is created once with the Kao ID name and is independent afterwards; its avatar must be a copy in the member's own `secondhand-avatars/<uid>/` folder.
   - R19c: `secondhand.shipping_addresses:write` (owner only, max 10, one default), read-only `secondhand.reviews` and `secondhand.member_ratings`, and the functions `secondhand.submit_review` (one per side of a completed order, editable for 30 days) and `secondhand.reply_review`.
4. **Hosting** — serve Kao ID's `index.html` for `/oauth/consent` (SPA fallback), like `/login`.
5. Production: add the real HTTPS redirect URI to the client, then update the registry. Never register wildcard or `http` non-loopback redirects.

Until step 3 is done the consent page shows "not registered" and only allows *Don't allow*; tokens of unregistered or suspended clients fail every request with `client_not_allowed`.

## 3. Secondhand sample code (Flutter web)

Dependencies: `http`, `crypto`, `jose` (JWS verification), `supabase_flutter` 2.18.x.

### 3.1 Config

```dart
// lib/core/config/kao_id_oauth_config.dart
final class KaoIdOAuthConfig {
  const KaoIdOAuthConfig({required this.issuer, required this.clientId, required this.redirectUri});

  final Uri issuer;          // https://<project>.supabase.co/auth/v1
  final String clientId;     // from Dashboard › OAuth Apps
  final Uri redirectUri;     // http://localhost:7357/auth/callback (dev)

  static const scopes = 'openid email profile';
  Uri get authorize => issuer.replace(path: '${issuer.path}/oauth/authorize');
  Uri get token => issuer.replace(path: '${issuer.path}/oauth/token');
  Uri get jwks => issuer.replace(path: '${issuer.path}/.well-known/jwks.json');
}
```

### 3.2 Start login (PKCE + state + nonce)

```dart
// lib/data/auth/kao_id_oauth_client.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String _random([int bytes = 32]) {
  final rng = Random.secure();
  return base64UrlEncode(List<int>.generate(bytes, (_) => rng.nextInt(256))).replaceAll('=', '');
}

String _challenge(String verifier) =>
    base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

Future<Uri> buildLoginUri(KaoIdOAuthConfig config, PendingLoginStore store) async {
  final verifier = _random(48), state = _random(), nonce = _random();
  await store.save(verifier: verifier, state: state, nonce: nonce); // sessionStorage, one-shot
  return config.authorize.replace(queryParameters: {
    'response_type': 'code',
    'client_id': config.clientId,
    'redirect_uri': config.redirectUri.toString(),
    'scope': KaoIdOAuthConfig.scopes,
    'state': state,
    'nonce': nonce,
    'code_challenge': _challenge(verifier),
    'code_challenge_method': 'S256',
  });
}
// launchUrl(await buildLoginUri(...), webOnlyWindowName: '_self');
```

### 3.3 Callback: check state, exchange the code, verify the id_token

```dart
Future<KaoIdTokens> completeLogin(Uri callback, KaoIdOAuthConfig config, PendingLoginStore store) async {
  final pending = await store.take(); // read and delete
  final params = callback.queryParameters;
  if (params['error'] != null) throw const KaoIdLoginCancelled();
  if (pending == null || params['state'] != pending.state) throw const KaoIdLoginInvalid();

  final response = await http.post(config.token, body: {
    'grant_type': 'authorization_code',
    'code': params['code'] ?? '',
    'redirect_uri': config.redirectUri.toString(),
    'client_id': config.clientId,
    'code_verifier': pending.verifier,
  });
  if (response.statusCode != 200) throw const KaoIdLoginInvalid();
  final tokens = KaoIdTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

  // id_token: signature via JWKS, then iss / aud / exp / nonce.
  final jwks = JsonWebKeyStore()..addKeySetUrl(config.jwks);
  final jwt = await JsonWebToken.decodeAndVerify(tokens.idToken, jwks);
  final claims = jwt.claims;
  if (claims.issuer.toString() != config.issuer.toString() ||
      !(claims.audience ?? const []).contains(config.clientId) ||
      claims['nonce'] != pending.nonce ||
      (claims.expiry?.isBefore(DateTime.now()) ?? true)) {
    throw const KaoIdLoginInvalid();
  }
  return tokens; // keep in memory + refresh token in secure/session storage
}
```

### 3.4 Use the token with Supabase and refresh it

```dart
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
  accessToken: () async => tokenStore.validAccessToken(), // refreshes when < 60 s left
);
// With `accessToken` set, `Supabase.instance.client.auth` is unavailable by design:
// sign-in, refresh and sign-out all go through the Kao ID OAuth client above.

Future<KaoIdTokens> refresh(KaoIdOAuthConfig config, String refreshToken) async {
  final response = await http.post(config.token, body: {
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken,
    'client_id': config.clientId,
  });
  if (response.statusCode != 200) throw const KaoIdSessionExpired(); // send to login again
  return KaoIdTokens.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}
```

Sign-out in Secondhand clears its stored tokens. A member can also disconnect the app in Kao ID (Security › Connected apps), which revokes the grant; the next refresh then fails and Secondhand must start login again.

### 3.5 Read live status instead of copying it

```dart
// lib/data/kao_id/kao_id_claims_repository.dart
Future<KaoIdClaims> loadClaims(SupabaseClient client) async {
  final json = await client.rpc<Map<String, dynamic>>('kao_id_claims_r18');
  return KaoIdClaims.fromJson(json);
}

bool canSell(KaoIdClaims c) =>
    c.accountState == 'active' &&
    c.verification?.kyc == 'approved' &&
    c.verification?.bank == true;
```

Response shape (sections appear only when the app is registered for them):

```json
{
  "sub": "uuid", "app": "secondhand_web", "account_state": "active",
  "kao_id": "K1IQ67RBF2N", "locale": "th", "checked_at": "2026-10-12T09:00:00Z",
  "profile": {"display_name": "…", "username": "…", "avatar_url": "…", "country_code": "TH"},
  "verification": {"email": true, "phone": false, "kyc": "approved", "bank": true, "kao_id_active": true},
  "business": [{"organization_id": "uuid", "name": "…", "status": "approved", "role": "owner",
                "business_kao_id": "…", "bank": true}]
}
```

`kyc` is one of `approved`, `pending`, `rejected`, `expired`, `not_submitted`. Call it on app start, on resume, and before seller actions; do not cache it for long. Locale: use `locale` as the default and keep the user's in-app choice under `kaosure.app.locale`.

## 4. What Secondhand must change

- Stop reading `identity_documents` (always refused for app tokens) and `bank_accounts` (not on the allow-list): use `verification.kyc`, `verification.bank` and `business[].bank`.
- Replace the same-origin `/login?return_to=` handoff with sections 3.2–3.4 once the client is registered.
- Order creation, payment and escrow stay server-side (RPCs on the allow-list); the app never decides payment status.

## 5. Security checklist

- [x] Public client, PKCE S256, `state` and `nonce` are one-shot and checked.
- [x] `id_token` verified against JWKS: signature, `iss`, `aud`, `exp`, `nonce`.
- [x] Access token lifetime is the project JWT expiry; refresh tokens rotate.
- [x] App tokens are restricted by the request guard (default deny) and RLS still applies to the member.
- [x] The guard checks the schema (`Accept-Profile` for GET/HEAD, `Content-Profile` otherwise; default `public`) and the method: POST/PATCH/PUT/DELETE on a table need a `:write` entry (R19a).
- [x] Kao ID's `profiles` row is read-only for every app token, also at the RLS level (restrictive policies `kao_id_profile_*_r19a`).
- [x] Orders, escrow, payments, wallets and withdrawals have no client write grants or open write policies; money moves only through server-side functions.
- [x] App tokens cannot write to the `identity-documents` or `avatars` storage buckets (restrictive storage policy `sso_app_storage_r18`). Storage, Realtime and Edge Functions do not run the PostgREST pre-request hook, so any new bucket or realtime table that holds Kao ID data must add the same `client_id` check.
- [x] Suspending an app in the registry stops all its tokens at the next request.
- [x] Consent page loads no remote logos and only follows https, loopback http or reverse-domain native redirects.
- [x] Checked 2026-10-12 with a real `secondhand_web` token: Supabase Auth accepts app tokens on `/auth/v1/user` (scopes do not limit it), so:
  - Password: `security_update_password_require_current_password` is on; the app token got `400 current_password_required`. Kao ID's change-password page sends the current password; password recovery sessions are exempt by Supabase.
  - Email: secure email change is on, so a change needs confirmation from both the old and the new address.
  - `user_metadata`: writable by any user token; no Kao ID policy or function reads it, and none may.
- [x] Phone (R19h): Supabase Auth still accepts `PUT /auth/v1/user {phone}` from an app token, but every SMS passes the Send SMS hook `kaoid_private.send_sms_hook_r19`. An OTP to a number other than the current one needs a 10-minute intent from `begin_phone_change_r19`, which only Kao ID's own session (no `client_id`) may create; otherwise the hook returns 403 and Auth rolls the change back. The member also gets a "phone changed" email.
- [ ] SMS delivery: the hook ends with `503 sms_delivery_not_configured`. Before phone OTP goes live, replace that return with a real provider call (HTTP hook / Edge Function) keeping the same intent check.
- [ ] Production: real HTTPS redirect URIs, MFA policy on for registry changes.

## 6. Checks

```powershell
flutter test test/features/sso
flutter analyze
flutter test
```

Database: `.tools/sso_r18_e2e_block.sql` runs after the migration inside a transaction that always rolls back (owner-only registry, protected-name rejection, guard allow/deny, suspended and unknown clients, storage buckets, legacy tables). `.tools/r19a_scope_e2e_block.sql` covers schema and method scoping, read-only `profiles` and the money tables.
