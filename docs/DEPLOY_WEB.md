# Web deployment (Firebase Hosting)

Kao ID and Secondhand are served from one origin, because Kao ID only sends members back to its own origin under `KAO_ID_ALLOWED_SERVICE_PATHS`:

| Path | App | Built from |
|---|---|---|
| `/` | Kao ID (`kaosure`) | `--base-href /` |
| `/secondhand/` | Secondhand (`kaosure_secondhand`) | `--base-href /secondhand/` |

The test phase uses the free Firebase address `https://<project-id>.web.app` and the current Supabase project. A separate production Supabase project comes later.

## Files

- `firebase.json`: serves `build/hosting`. It answers `/secondhand/**` with Secondhand's `index.html` and everything else with Kao ID's `index.html` (SPA fallback, so `/secondhand/auth/callback` and deep links load). `/secondhand` redirects to `/secondhand/`. Every response carries:
  - HSTS
  - `nosniff`
  - no framing (`X-Frame-Options: DENY`, `frame-ancestors 'none'`)
  - `strict-origin-when-cross-origin` referrer policy
  - a restrictive `Permissions-Policy`
  - `Cache-Control: no-cache`, so browsers revalidate by ETag and a deploy never mixes old and new files.
- `.firebaserc`: the default Firebase project ID.
- `deploy/build_web.ps1`: builds both apps and assembles `build/hosting`.
- `deploy/web.env.example`: the only build values allowed. Copy it to `deploy/web.env`, which is git-ignored.

## Build values

Everything passed to a web build is compiled into public JavaScript. `deploy/web.env` therefore holds only public values, and the script refuses any other key, any `sb_secret_` key and any JWT whose role is not `anon`:

| Key | Value |
|---|---|
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Publishable (or legacy anon) key |
| `KAO_ID_CLIENT_ID` | Public OAuth client of Secondhand |

The script derives the rest from the site URL:

| App | Key | Value |
|---|---|---|
| Kao ID | `APP_URL` | `https://<project-id>.web.app` |
| Kao ID | `KAO_ID_ALLOWED_SERVICE_PATHS` | `/secondhand` |
| Secondhand | `KAO_ID_REDIRECT_URI` | `https://<project-id>.web.app/secondhand/auth/callback` |
| Secondhand | `KAO_ID_WEB_URL` | `https://<project-id>.web.app` |

Server secrets (`SUPABASE_SERVICE_ROLE_KEY`, mail and payment credentials) belong only in Supabase Edge Function secrets, never in a web build.

## One-time setup

The owner does these steps with their own accounts.

1. **Firebase:** create the project in the Firebase console, then put its ID in `.firebaserc` (`projects.default`). Sign in once with `npx firebase-tools login`.
2. **Build values:** copy `deploy/web.env.example` to `deploy/web.env` and fill it in.
3. **Supabase Dashboard › Authentication › URL Configuration:**
   - Site URL: `https://<project-id>.web.app`. The OAuth consent page (`/oauth/consent`) is opened on the Site URL, so while it points here, Secondhand sign-in from local development also uses the deployed Kao ID consent page.
   - Redirect URLs: add `https://<project-id>.web.app/**` (password recovery and email links).
4. **Supabase Dashboard › Authentication › OAuth Apps › Kao Secondhand:** add the redirect URI `https://<project-id>.web.app/secondhand/auth/callback`. Keep `http://localhost:7357/auth/callback` for development.
5. **Email and SMS:** the built-in Supabase mailer only reaches project team members and is rate limited. Testing with other people needs your own SMTP (Authentication › Emails › SMTP) and an SMS provider for phone verification (Authentication › Providers › Phone).
6. **Kao ID notification email (optional for testing):** set the `kaoid-mail-worker` secrets (`RESEND_API_KEY`, `KAOID_MAIL_FROM`, `KAOID_PUBLIC_URL=https://<project-id>.web.app`, `KAOID_WORKER_SECRET`, then `KAOID_MAIL_ENABLED=true`) and schedule it (`docs/README_R10A.md`).

## Build and deploy

```powershell
cd D:\Developer\projects\kaosure
powershell -ExecutionPolicy Bypass -File deploy\build_web.ps1
npx firebase-tools deploy --only hosting
```

`build_web.ps1` reads the site URL from `.firebaserc` (`https://<project-id>.web.app`); pass `-SiteUrl` for another origin. It stops before building when:
- the project ID is missing;
- the URL is not https (http is only allowed for localhost);
- a build value is missing, unknown or secret.

Each run replaces `build/hosting`.

## Local rehearsal

```powershell
powershell -ExecutionPolicy Bypass -File deploy\build_web.ps1 -SiteUrl http://localhost:5000
npx firebase-tools emulators:start --only hosting --project demo-kaosure
```

This checks rewrites and deep links such as `/secondhand/items/<id>`. The Hosting emulator does not send the custom headers, so check those after a real deploy. Sign-in needs the matching redirect URI on the OAuth client.

## After each deploy

1. Run `curl -I https://<project-id>.web.app/secondhand/` and confirm the headers listed in Files above.
2. On desktop, iOS Safari and Android Chrome:
   - open `/` and `/secondhand/`, a product link and a category link, and reload each;
   - check that `/secondhand` redirects to `/secondhand/`.
3. Walk through the full flow:
   1. Sign up in Kao ID.
   2. Verify email and phone.
   3. Pass KYC and bank verification.
   4. Open Secondhand from Kao ID.
   5. Open the shop and list an item.
   6. Buy with another account using the mock payment.
   7. Ship and receive.
   8. Release the money.
   9. Review.
   10. Withdraw.
4. Sign out of Secondhand and sign in again without a password.

Rollback: Firebase console › Hosting › Release history › Roll back.

## Before public launch

- [ ] Turn off the mock payment (`secondhand.market_settings.mock_payment_enabled`). It stays on during the test phase only.
- [ ] Connect real money in and out: a payment gateway and the PromptPay top-up account.
- [ ] Move to a separate production Supabase project, then repeat the one-time setup there.
- [ ] Merge the Kao ID release branch into `main` and deploy from `main` only.
- [ ] Optionally use a company domain (Firebase Hosting › Add custom domain), then update the Site URL, redirect URLs and OAuth redirect URI to it.
