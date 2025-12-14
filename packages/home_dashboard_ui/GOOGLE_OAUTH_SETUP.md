Google OAuth / Sign-In Setup (frontend notes)

What I added:
- A Google sign-in button in the login UI (`login_screen.dart`) wired to
  `AuthService.signInWithGoogle()` as a placeholder.
- A placeholder `signInWithGoogle()` method in `packages/home_dashboard_ui/lib/services/auth_service.dart`.

Why this is a placeholder:
- Full Google sign-in requires platform-specific client code and backend support.

Recommended next steps to fully implement Google sign-in:

1) Backend
- Add an OAuth client on the backend (Google) and implement an endpoint that
  accepts an OAuth token or authorization code and exchanges it for an app
  session (access + refresh tokens). Example endpoints:
  - `POST /auth/oauth/google` (accepts id_token or auth code) -> returns app tokens
- Validate the Google token server-side and create/lookup corresponding user
  records. Ensure only registered users may log in if you enforce that rule.

2) Client (mobile/web)
- For Android/iOS: add the `google_sign_in` Flutter package and implement the
  sign-in flow to obtain an `idToken` or `accessToken` from Google.
- For web or OIDC flows, implement the appropriate redirect flow and exchange
  the authorization code with your backend.
- After obtaining the Google token, POST it to your backend endpoint to get
  application tokens and complete the login.

3) Security
- Use HTTPS everywhere and validate token audiences and issuers.
- Implement token rotation / refresh on the backend and on the client.

4) UX
- Show clear errors when Google sign-in isn't configured or backend support
  is missing (the placeholder throws an informative error currently).

Packages to consider (client):
- `google_sign_in`
- `flutter_web_auth` (for web/redirects)

Files updated:
- `packages/home_dashboard_ui/lib/screens/login_screen.dart` — added button + handler
- `packages/home_dashboard_ui/lib/services/auth_service.dart` — added placeholder method

If you want, I can:
- Implement the client-side `google_sign_in` flow (requires adding dependency).
- Implement a minimal backend exchange call happy-path (calls your expected endpoint).
- Wire successful sign-in to the existing token storage logic.

What I implemented for you in this commit:
- Added `google_sign_in` dependency to `packages/home_dashboard_ui/pubspec.yaml`.
- Implemented a client-side flow in `AuthService.signInWithGoogle()` that uses
  `google_sign_in` to obtain an `id_token` and posts it to `/auth/oauth/google`.
- Added a branded-styled Google sign-in button to `login_screen.dart`.

Notes & platform setup (important):
- Android: add `google-services.json` and configure SHA-1/sha-256 for app
  credentials in Google Cloud Console. Add `com.google.gms:google-services` config
  if using Firebase or follow package docs for standalone OAuth.
- iOS: add `GoogleService-Info.plist` and set reversed client id URL scheme.
- Web: configure auth client IDs and authorized origins, or use an OIDC redirect flow.

Testing locally:
- Run `flutter pub get` in the workspace root (or the package folder) to fetch the
  new dependency.
- Provide a backend endpoint at `/auth/oauth/google` that accepts `POST { id_token }
  ` and returns `{ access_token, refresh_token, user }`.

If you'd like, I can now:
- (A) Wire a fallback flow for web (flutter_web_auth) and add platform-specific notes.
- (B) Implement the backend call more defensively (retry, better error parsing).
- (C) Add a small test that validates the login UI shows the Google button.

Tell me which next step you prefer.