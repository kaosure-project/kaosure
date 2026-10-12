# Kao ID ↔ Secondhand web handoff R1

## What this patch connects

- Secondhand sends the browser to the existing Kao ID `/login` route with a `return_to` path.
- Kao ID captures that target on login only and stores it locally as a one-shot pending navigation.
- Existing authenticated users continue through the normal bootstrap check.
- After bootstrap (or profile completion), Kao ID asks `account_access_r10d` to confirm the session is active, then returns the browser to Secondhand.
- The Secondhand browser loads the existing Supabase session and uses the same `auth.uid()`. No second account is created and no token is put in the URL.

## Deployment requirements

1. Serve Kao ID and Secondhand on the same exact HTTPS origin, with Secondhand mounted at `/secondhand/` (for example, `https://members.example/` and `https://members.example/secondhand/`).
2. Initialize both apps with the same Supabase project URL and publishable key.
3. Configure Secondhand `KAO_ID_LOGIN_URL` to the same-origin Kao ID login route, such as `https://members.example/login`.
4. Build Kao ID with `APP_URL=https://members.example` and `KAO_ID_ALLOWED_SERVICE_PATHS=/secondhand`. Add other same-origin service path prefixes explicitly, comma-separated, only after those services are deployed.
5. Configure the web server to route `/login` to Kao ID and `/secondhand/*` to the Secondhand Flutter web app. Use a local reverse proxy for local end-to-end testing; different localhost ports are different browser origins.

## Limits

This R1 is a same-origin browser session handoff. It does not enable cross-domain SSO, create or register an OAuth client, or support native app callbacks. Those require a separate OAuth/OIDC Authorization Code + PKCE integration and configuration on the central identity provider.

## Checks

From the Kao ID project root:

```powershell
flutter pub get
flutter test test/auth/kao_id_sso_handoff_test.dart
flutter analyze
flutter test
```

End-to-end: signed-out user clicks Secondhand Login → Kao ID login → successful sign-in → active-account check → return to the same-origin Secondhand path → verify the same Supabase Auth user is loaded. Then verify a foreign origin, unregistered path, inactive account, and failed login do not return as an authenticated member.
