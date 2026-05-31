# BUG-001: “This month” budget marked Expired when created on last calendar day

| Field | Value |
|-------|-------|
| **Bug ID** | BUG-001 |
| **Status** | Open |
| **Severity** | Major |
| **Priority** | P2 |
| **Discovery** | TC-BUD-001, CH-01 |

## Title

Budget for current month shows as **Expired** immediately after save on the last day of the month

## Short description

Creating a budget with the **This month** quick period on **31 May 2025** saves successfully, but the app classifies **Groceries** as expired right away. It appears under **Expired** on the Budgets tab and triggers the expired-budget banner on Home instead of an active progress card.

**Impact:** Users cannot rely on monthly budgets on month-end; dependent flows (e.g. TC-BUD-002 progress tracking) are blocked.

## Steps to reproduce

1. Set device/simulator date to **31 May 2025** (or any last day of a calendar month).
2. Complete onboarding and open **Budgets** → **+** (new budget).
3. Tap **This month** (start = 1st, end = last day of month).
4. Enter name **Groceries**, limit **200**, account **Cash**, category **Food & Dining**.
5. Save.
6. Observe **Budgets** tab sections and **Home** budget area.

## Expected vs actual

| | Expected | Actual |
|---|----------|--------|
| Budget list | **Groceries** under **Active** for May 2025 | **Groceries** under **Expired** |
| Home | Active budget card ($0 / $200, on-track) | Expired-budget banner for **Groceries** |
| Period | Active through end of 31 May 2025 | Treated as expired immediately after save |

**Expected result (one line):** A budget created for the current month remains **Active** through the last day of that month.

**Actual result (one line):** The budget is classified **Expired** as soon as it is saved on the last calendar day.

## Environment

| Field | Value |
|-------|-------|
| App | Kakk/កាក់ 1.0.0+1 |
| Platform | iOS Simulator — iPhone 17 Pro (iOS 26.2) |
| Locale | English |
| Test date | 31 May 2025 |
| Related tests | TC-BUD-001 (Fail), TC-BUD-002 (Blocked) |
| Related charter | CH-01 |

## Evidence

| File | Description |
|------|-------------|
| `docs/testing/evidence/BUG-001-budgets-expired-section.png` | Budgets tab — Groceries under Expired (capture when available) |
| `docs/testing/evidence/BUG-001-home-expired-banner.png` | Home expired banner instead of progress card (capture when available) |
| `docs/testing/evidence/CH-01-budget-expired-section.png` | Optional duplicate from charter session |

## Technical note (for developers — optional)

`BudgetFormScreen` sets `_endDate` to `DateTime(year, month + 1, 0)` (midnight at start of the last day). Save uses `_endDate.millisecondsSinceEpoch`. `Budget.isExpired` uses `DateTime.now().millisecondsSinceEpoch > endDate`, so any time after 00:00 on the last day of the month the budget is already expired.

**Likely fix:** Store end-of-day for `endDate` (e.g. 23:59:59.999 on last day) or use inclusive date comparison (`>=` start of next day).

## Links

- Test case: [test-case-suite.md](../test-case-suite.md) — TC-BUD-001
- Charter: [charter-01-data-integrity.md](../charters/charter-01-data-integrity.md) — CH-01
