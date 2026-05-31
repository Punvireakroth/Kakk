# Charter: Currency and conversion edge cases

- **Charter ID:** CH-02
- **Tester:** QA Team
- **Date / Duration:** 2026-05-29, 60 min
- **Mission:** Explore multi-currency accounts and exchange-rate behavior when online, offline, and after reconnect.
- **Scope:**
  - **In:** Add account with **KHR** and **USD**, transaction form currency picker, conversion preview, Home total display.
  - **Out:** Historical rate accuracy vs. central bank, Google Drive backup currency metadata.
- **Oracles:**
  - Same-currency transactions save without conversion prompt.
  - Cross-currency save shows rate or clear error; no silent wrong amount posted.
  - Offline behavior surfaces user-visible message (not blank UI).

## Session log

| Time | Action | Observation |
|------|--------|-------------|
| 11:00 | Created **KHR Wallet** account (currency **KHR**, opening balance **400000**) | Account card shows **៛** formatting on Home |
| 11:08 | On **Cash** (USD), added **$20** expense — no conversion UI | Expected: same currency, direct save |
| 11:15 | On **KHR Wallet**, added expense **50000 KHR** for **Street food** | Saved in KHR; balance **350000 KHR** |
| 11:22 | Switched transaction input currency to **USD** while account is **KHR** | Conversion row appeared; rate fetched (~1 USD ≈ 4100 KHR band) |
| 11:30 | Enabled **Airplane Mode**; entered **$10 USD** expense on **KHR Wallet** | Spinner then **Conversion Failed** dialog: *Unable to convert USD to KHR* with **Cancel**, **Retry**, **Save Anyway** |
| 11:38 | Tapped **Retry** (still offline) | Dialog reappeared; no crash |
| 11:42 | Tapped **Cancel** | Form stayed open; no partial transaction |
| 11:48 | Disabled Airplane Mode; retried same **$10** entry | Rate fetched; converted amount shown before save |
| 11:55 | Saved converted expense | **KHR Wallet** balance decreased by converted amount only (single ledger entry) |
| 11:58 | Home carousel: **Cash** and **KHR Wallet** show native currency symbols | No erroneous cross-currency merge on cards |

## Findings

1. **Same-currency path:** Pass — no unnecessary conversion step.
2. **Online cross-currency:** Pass — rate preview and converted debit applied correctly.
3. **Offline cross-currency:** Pass — blocking dialog with retry/cancel; no silent data corruption.
4. **Stale cache:** Not fully exercised (session under 5 min cache window); follow-up charter note for Phase 3.

## Bugs filed

- None (session passed oracles)

## Evidence

- `docs/testing/evidence/CH-02-conversion-failed-dialog.png` (optional)

## Follow-up

- Add **TC-CUR-001** suggestion: offline save blocked unless user explicitly chooses **Save Anyway**
- Phase 2 unit tests on `ExchangeRateService` timeout and stale-cache fallback
