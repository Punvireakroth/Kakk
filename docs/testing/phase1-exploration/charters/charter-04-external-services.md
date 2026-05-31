# Charter: External services resilience

- **Charter ID:** CH-04
- **Tester:** QA Team
- **Date / Duration:** 2026-05-30, 60 min
- **Mission:** Explore Google sign-in cancellation, offline mode, and invalid Gemini API key handling without silent failures.
- **Scope:**
  - **In:** **More → Backup** Google sign-in, exchange-rate dependent flows, **More → AI Assistant** Gemini key settings, Airplane Mode.
  - **Out:** Production Google OAuth consent screen branding review, load testing of exchange API.
- **Oracles:**
  - Cancelled sign-in returns to prior screen with no crash.
  - Network/API failures show actionable error (snackbar or dialog).
  - Invalid AI key rejected on save or on first suggestion request.

## Session log

| Time | Action | Observation |
|------|--------|-------------|
| 09:00 | **More → Backup → Sign in with Google** | Google account picker presented |
| 09:02 | Dismiss picker / tap outside (cancel) | Returned to Backup screen; still signed out; no crash |
| 09:08 | Airplane Mode **On** → open add transaction on USD account | Same-currency expense still saves locally |
| 09:15 | Cross-currency attempt (USD input, KHR account) | **Conversion Failed** dialog — same as CH-02 |
| 09:22 | Airplane Mode **Off** | Conversion succeeds on retry |
| 09:30 | **More → AI Assistant** → enter invalid key `invalid-key-12345` → Save | Error feedback; key not treated as valid |
| 09:38 | Add income **$200** → open role split / AI suggestion flow | Message indicates API key invalid or request failed; no app crash |
| 09:45 | Replace with empty key → Save | Validation: cannot save empty key |
| 09:50 | Skipped live Google sign-in completion (no test account in sim) | Cancel path verified; full Drive backup deferred to manual QA with test Google account |
| 09:58 | Review Backup screen while signed out | **Backup to Google Drive** disabled or prompts sign-in first — no silent upload |

## Findings

1. **Google sign-in cancel:** Pass — graceful return, no partial auth state observed.
2. **Offline local CRUD:** Pass — SQLite operations work without network.
3. **Gemini invalid key:** Pass — user-visible failure; app remains usable without AI.
4. **Drive backup happy path:** Not executed (requires real Google test account); cancel/resilience paths covered.

## Bugs filed

- None

## Evidence

- `docs/testing/evidence/CH-04-google-signin-cancel.png` (optional)
- `docs/testing/evidence/CH-04-gemini-invalid-key.png` (optional)

## Follow-up

- Postman collection (Phase 2) for `open.er-api.com` exchange endpoint
- Manual sign-in test with team Google account before release demo
