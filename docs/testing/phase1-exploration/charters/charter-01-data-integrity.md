# Charter: Data integrity under rapid transaction churn

- **Charter ID:** CH-01
- **Tester:** QA Team
- **Date / Duration:** 2026-05-28, 60 min
- **Mission:** Explore rapid add, edit, and delete of transactions to discover balance drift, duplicate rows, or stale budget indicators.
- **Scope:**
  - **In:** Transactions tab, Home account balances, Budgets tab progress/expired sections, swipe delete, edit transaction amount/category.
  - **Out:** Google backup, AI role splits, multi-device sync.
- **Oracles:**
  - Account balance matches manual sum of visible transactions (± rounding).
  - Delete reverses balance change; edit adjusts delta correctly.
  - Budget spent/limit reflects categorized expenses in the active period.

## Session log

| Time | Action | Observation |
|------|--------|-------------|
| 10:02 | Baseline: **Cash** at **$0.00** after fresh onboarding reset | Home and Transactions agree |
| 10:08 | Added 5 expenses in quick succession ($12, $8.50, $25, $3.99, $40) — mixed categories | Each save showed green snackbar; list updated immediately |
| 10:15 | Spot-check: Home **Cash** = **−$89.49** | Matches sum of five expenses; oracle pass |
| 10:22 | Edited **$25** expense → **$30** (+$5) | Balance updated to **−$94.49** without relaunch |
| 10:28 | Swipe-deleted **$40** row | Balance restored to **−$54.49**; row removed |
| 10:35 | Created **Groceries** budget ($200, Food & Dining, **This month**) on **31 May 2025** | Save succeeded but budget landed in **Expired** section immediately |
| 10:42 | Added **$50** Food expense expecting Home budget card update | No active progress card — only expired banner for **Groceries** |
| 10:50 | Force-quit and relaunch | All five edited/deleted transactions persisted; balances unchanged after restart |
| 10:58 | Retried budget with custom end date **31 May 23:59** (manual date picker) | Still classified **Expired** on last calendar day — same symptom |

## Findings

1. **Transaction CRUD integrity:** Pass — balances tracked add, edit, delete, and survived app restart.
2. **Budget on month-end:** Fail — **Groceries** budget treated as expired on creation day; blocks progress verification.
3. **Minor observation (not filed):** Delete-account dialog text mentions cascade delete, but non-empty accounts are blocked with FK error (see TC-ACC-003).

## Bugs filed

- [BUG-001](../bug-reports/BUG-001-budget-expired-on-last-day-of-month.md) — “This month” budget marked Expired on last calendar day

## Evidence

- `docs/testing/evidence/CH-01-balance-after-rapid-adds.png` (optional)
- `docs/testing/evidence/CH-01-budget-expired-section.png` (optional; same scenario as BUG-001)

## Follow-up

- Formalized as **TC-BUD-001** / **TC-BUD-002** in `test-case-suite.md`
- Phase 2 unit test: inclusive end-date comparison for `Budget.isExpired`
- Re-run CH-01 budget portion after fix on both last day and mid-month dates
