# Charter: Persistence, interruption, and local backup

- **Charter ID:** CH-03
- **Tester:** QA Team
- **Date / Duration:** 2026-05-29, 90 min
- **Mission:** Explore data survival when the app is killed mid-form, after normal saves, and through local backup export/import.
- **Scope:**
  - **In:** Transaction add form, budget form, **More → Backup** local export/import, force-quit via simulator.
  - **Out:** Google Drive restore (covered in CH-04), Developer reset-to-onboarding except for final verification.
- **Oracles:**
  - Unsaved form data may be lost (acceptable) but must not corrupt existing DB rows.
  - Committed transactions survive restart.
  - Local backup round-trip restores accounts and transactions.

## Session log

| Time | Action | Observation |
|------|--------|-------------|
| 14:00 | Note baseline: **Cash** **$499.99**, 3 transactions visible | Starting from post–Part A execution state |
| 14:08 | Open add-transaction form; enter **Half entry** / **$77.77** / Food — do **not** save | Form in progress |
| 14:09 | Force-quit app from iOS app switcher | — |
| 14:10 | Relaunch → Transactions tab | **Half entry** not in list; **Cash** still **$499.99** — oracle pass (no ghost row) |
| 14:18 | Add and save **Coffee** **$4.50** expense | Balance **$495.49** |
| 14:20 | Force-quit immediately after snackbar | — |
| 14:21 | Relaunch | **Coffee** present; balance **$495.49** persisted |
| 14:30 | Open budget form, enter name **Transport**, limit **100** — kill app before save | No new budget row after relaunch |
| 14:40 | **More → Backup & Restore → Export local backup** | Success message; file listed in local backups |
| 14:52 | **More → Developer → Reset to Onboarding** (clean slate) | App returned to onboarding |
| 14:55 | Complete minimal onboarding (**Test Restore** / **USD** / **Cash**) | Empty wallet |
| 15:00 | **Import local backup** from step 14:40 | Restore completed; prior **Coffee** transaction and **Savings** account reappeared |
| 15:05 | Verify **Cash** balance matches pre-reset snapshot | Within **$495.49** expected range after restore |

## Findings

1. **Mid-form kill:** Pass — partial forms discarded; no corruption of existing data.
2. **Post-save kill:** Pass — committed transactions durable.
3. **Local backup round-trip:** Pass — accounts and transactions restored after intentional reset.
4. **Budget mid-form kill:** Pass — incomplete budget not persisted.

## Bugs filed

- None

## Evidence

- `docs/testing/evidence/CH-03-backup-restore-list.png` (optional)

## Follow-up

- E2E journey 2 (budget lifecycle) should include restart step after Phase 2 automation
- Document restore UX: user must complete onboarding before import on clean install
