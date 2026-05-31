# Kakk — Black-Box Test Case Suite

## Test Environment

| Field | Value |
|-------|-------|
| **App name** | Kakk/កាក់ |
| **App version** | 1.0.0+1 |
| **Platform** | iOS Simulator — iPhone 17 Pro (iOS 26.2) |
| **Flutter SDK** | 3.x (project SDK ^3.10.0) |
| **Locale (default)** | English (`en`) |
| **Network** | Wi‑Fi on (exchange-rate API available) |
| **Tester** | QA Team |
| **Execution date** | 2026-05-31 |
| **Build command** | `flutter run -d "iPhone 17 Pro"` |
| **Fresh install** | Uninstall `com.example.kakk` before TC-ONB-001; use **More → Developer → Reset to Onboarding** between dependent runs when noted |

## Suite Summary

| Metric | Target | Actual |
|--------|--------|--------|
| Total cases | ≥10 | **11** |
| Onboarding | ≥1 | 1 |
| Transactions | ≥3 | 5 |
| Budgets | ≥2 | 2 |
| Accounts | ≥2 | 2 |
| Settings / backup | ≥1 | 1 |
| Sad-path cases | ~40% | 4 / 11 (36%) |
| Techniques used | ≥4 distinct | 6 (Use Case, Equivalence, Boundary, State Transition, Decision Table, Error Guessing) |
| Pass | — | **9** |
| Fail | — | **1** |

### Technique coverage

| Technique | Test case IDs |
|-----------|---------------|
| Use Case Testing | TC-ONB-001, TC-TXN-001, TC-BUD-001, TC-ACC-001 |
| Equivalence Partitioning | TC-TXN-002, TC-TXN-004 |
| Boundary Value Analysis | TC-TXN-003 |
| State Transition | TC-TXN-005, TC-ACC-002 |
| Decision Table | TC-BUD-002 |
| Error Guessing | TC-ACC-003, TC-SET-001 |

---

## Test Cases

### TC-ONB-001 — Complete onboarding creates default account

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-ONB-001 |
| **Test Title** | Complete onboarding creates default account with chosen currency |
| **Technique Used** | Use Case Testing |
| **Pre-conditions** | Fresh install (no prior app data); device online; onboarding flag `show_onboarding = true`. |
| **Test Steps** | 1. Launch the app.<br>2. Swipe through all four intro slides; tap **Next** / **Get Started** until the setup flow begins.<br>3. Enter display name **Alex Tester**; tap **Continue**.<br>4. Select currency **USD**; tap **Continue**.<br>5. Enter account name **Cash**; tap **Create Account** / **Finish**.<br>6. On the success screen, tap **Go to Home** (or equivalent).<br>7. Observe the Home tab account cards and balance. |
| **Test Data** | Display name: `Alex Tester`; Currency: `USD`; Account name: `Cash`; Initial balance: `0.00` |
| **Expected Result** | Onboarding completes without error. Home shows one account named **Cash** with balance **$0.00** (or USD equivalent). Bottom navigation (Home, Transactions, Budgets, More) is visible. Relaunching the app skips onboarding and lands on Home. |
| **Actual Result** | Completed full onboarding on fresh install: swiped through four intro slides, entered display name **Alex Tester**, kept default currency **USD**, created account **Cash**, and tapped **Start Using CashChew**. Home loaded with bottom navigation (Home, Transactions, Budgets, More) and one account card showing **CASH** at **$0.00**. Force-quit and relaunched the app onboarding was skipped and Home opened directly with the **Cash** account still present. No errors or unexpected screens observed. |
| **Status** | Pass |
| **Post-conditions** | User profile and default **Cash** account persisted; `show_onboarding` false; expense/income categories seeded. |

---

### TC-TXN-001 — Add valid expense decreases account balance

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-TXN-001 |
| **Test Title** | Add valid expense decreases account balance |
| **Technique Used** | Use Case Testing |
| **Pre-conditions** | TC-ONB-001 complete; **Cash** account balance **$0.00**; on **Transactions** tab. |
| **Test Steps** | 1. Tap the **+** / add control on Transactions.<br>2. Ensure type is **Expense**.<br>3. Enter title **Lunch**, amount **15.00**, category **Food** (or first expense category), account **Cash**, today’s date.<br>4. Tap **Save** / **Add Transaction**.<br>5. Return to Transactions list and Home tab; note **Cash** balance. |
| **Test Data** | Title: `Lunch`; Amount: `15.00`; Type: Expense; Category: Food; Account: Cash |
| **Expected Result** | Save succeeds (confirmation snackbar). Transaction **Lunch** appears in list with **-$15.00**. **Cash** balance on Home shows **-$15.00** or **$0.00** minus 15 depending on display rules (balance decreased by 15). |
| **Actual Result** | Opened **Transactions** tab and tapped **+**. **Expense** was selected by default. Chose category **Food & Dining**, entered amount **$15.00** via the amount dialog, title **Lunch**, and confirmed **Cash** as the account. Tapped **Add Transaction** green snackbar **“Transaction added successfully”** appeared. **Lunch** showed in the transaction list with **-$15.00** (red). Switched to **Home** **CASH** balance updated from **$0.00** to **-$15.00**. Behavior matched expected balance decrease. |
| **Status** | Pass |
| **Post-conditions** | One expense transaction stored; account balance reflects −15.00. |

---

### TC-TXN-002 — Add income increases account balance

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-TXN-002 |
| **Test Title** | Add income increases account balance (valid partition) |
| **Technique Used** | Equivalence Partitioning (valid income amount class) |
| **Pre-conditions** | **Cash** balance known (e.g. **-$15.00** after TC-TXN-001); Transactions tab open. |
| **Test Steps** | 1. Tap **+** to add a transaction.<br>2. Switch type to **Income**.<br>3. Enter title **Paycheck**, amount **500.00**, category **Salary** (or first income category), account **Cash**.<br>4. Save.<br>5. If an income **role split** sheet appears, accept defaults or dismiss per on-screen guidance, then confirm save completes.<br>6. Verify list and Home balance. |
| **Test Data** | Title: `Paycheck`; Amount: `500.00`; Type: Income; Category: Salary; Account: Cash |
| **Expected Result** | Income saved; list shows **+$500.00** (green). **Cash** balance increases by 500 relative to pre-test balance (e.g. **$485.00** if starting from −15). |
| **Actual Result** | Opened **Transactions** tab and tapped **+**. Switched type from **Expense** to **Income**. Selected category **Salary**, entered amount **$500.00** via the amount dialog, title **Paycheck**, and confirmed **Cash** as the account. Tapped **Add Transaction** an income **role split** sheet appeared; skipped it (did not assign splits). Save completed with green snackbar **“Transaction added successfully”**. **Paycheck** appeared in the transaction list with **+$500.00** (green). Switched to **Home** **CASH** balance updated from **-$15.00** to **$485.00** (+$500.00). Behavior matched expected balance increase. |
| **Status** | Pass |
| **Post-conditions** | Income transaction persisted; balance increased by 500.00. |

---

### TC-TXN-003 — Minimum positive amount 0.01 accepted

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-TXN-003 |
| **Test Title** | Boundary amount 0.01 is accepted for expense |
| **Technique Used** | Boundary Value Analysis |
| **Pre-conditions** | At least one account exists; Transactions add form reachable. |
| **Test Steps** | 1. Open add-transaction form (Expense).<br>2. Enter title **Penny**, amount **0.01**, valid category and **Cash** account.<br>3. Save.<br>4. Confirm transaction appears and balance changes by **0.01**. |
| **Test Data** | Title: `Penny`; Amount: `0.01` (lower valid boundary); Type: Expense |
| **Expected Result** | **0.01** is accepted (no validation error). Transaction saved; balance decreases by **$0.01**. |
| **Actual Result** | Opened **Transactions** tab and tapped **+**. **Expense** was selected by default. Chose category **Food & Dining**, entered amount **$0.01** via the amount dialog, title **Penny**, and confirmed **Cash** as the account. Tapped **Add Transaction** green snackbar **“Transaction added successfully”** appeared (no validation error for minimum amount). **Penny** showed in the transaction list with **-$0.01** (red). Switched to **Home** **CASH** balance updated from **$485.00** to **$484.99** (−$0.01). Lower valid boundary accepted as expected. |
| **Status** | Pass |
| **Post-conditions** | Micro-transaction stored; balance adjusted by 0.01. |

---

### TC-TXN-004 — Zero amount rejected (invalid partition)

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-TXN-004 |
| **Test Title** | Zero amount rejected with validation feedback |
| **Technique Used** | Equivalence Partitioning (invalid amount class: zero) |
| **Pre-conditions** | Add-transaction form open; category and account selected. |
| **Test Steps** | 1. Select Expense, category **Food**, account **Cash**.<br>2. Enter title **Free sample**, amount **0**.<br>3. Tap Save.<br>4. Observe UI feedback; confirm no new row in transaction list. |
| **Test Data** | Title: `Free sample`; Amount: `0`; Type: Expense |
| **Expected Result** | Save blocked. User sees error (snackbar or inline) such as **“Please enter a valid amount”**. No transaction created; balance unchanged. |
| **Actual Result** | Opened **Transactions** tab and tapped **+**. **Expense** selected; chose category **Food & Dining**, account **Cash**, title **Free sample**. Entered amount **0** via the amount dialog and tapped **Add Transaction**. Save was blocked red snackbar displayed **“Please enter a valid amount”**; form remained open. Returned to transaction list no row titled **Free sample**; **Penny** and prior transactions unchanged. **Home** **CASH** balance remained **$484.99**. Invalid zero-amount partition rejected as expected. |
| **Status** | Pass |
| **Post-conditions** | No new transaction; balances unchanged. |

---

### TC-TXN-005 — Delete expense restores balance

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-TXN-005 |
| **Test Title** | Delete expense restores account balance (state transition) |
| **Technique Used** | State Transition (create → persist → delete → balance restored) |
| **Pre-conditions** | Expense **Lunch** **$15.00** exists from TC-TXN-001 (or create one); note **Cash** balance before delete. |
| **Test Steps** | 1. Open **Transactions** tab; locate **Lunch** **$15.00**.<br>2. Swipe row left to reveal **Delete**; tap **Delete**.<br>3. Confirm in dialog.<br>4. Verify row removed and Home **Cash** balance increased by **15.00** vs. pre-delete. |
| **Test Data** | Transaction to delete: `Lunch`, `$15.00` expense |
| **Expected Result** | Confirmation dialog appears; after confirm, snackbar success. Transaction removed from list. **Cash** balance restored by **+$15.00** relative to pre-delete. |
| **Actual Result** | Opened **Transactions** tab; **Lunch** **-$15.00** was visible in the list with **Cash** balance at **$484.99** on **Home**. Swiped the **Lunch** row left to reveal **Delete**; tapped **Delete**. Confirmation dialog **“Are you sure you want to delete ‘Lunch’?”** appeared; tapped confirm. Green snackbar **“Transaction deleted successfully”** displayed. **Lunch** no longer appeared in the transaction list (**Paycheck**, **Penny**, and other rows unchanged). Switched to **Home** **CASH** balance updated from **$484.99** to **$499.99** (+$15.00). Delete restored the account balance as expected. |
| **Status** | Pass |
| **Post-conditions** | Transaction deleted from DB; account balance recalculated. |

---

### TC-BUD-001 — Create monthly budget appears on Home

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-BUD-001 |
| **Test Title** | Create monthly budget with categories shows on Home |
| **Technique Used** | Use Case Testing |
| **Pre-conditions** | Onboarding complete; at least one expense category available; **Budgets** tab accessible. |
| **Test Steps** | 1. Open **Budgets** tab → **New Budget** / **+**.<br>2. Tap **This month** (or confirm default dates are 1st–last day of current month).<br>3. Name **Groceries**, limit **200**.<br>4. Select account **All accounts** or **Cash**; select category **Food & Dining**.<br>5. Save.<br>6. On **Budgets** tab, note section placement (Active vs Expired).<br>7. Open **Home** tab; locate budget section and any expired banner. |
| **Test Data** | Name: `Groceries`; Limit: `200`; Category: Food & Dining; Period: current calendar month (1 May–31 May 2025); **Execution date:** 31 May 2025 (last day of month) |
| **Expected Result** | Budget saves successfully. **Groceries** appears under **Active** budgets (not Expired). On Home, budget card shows limit **$200**, spent **$0** (or current spend), progress bar at 0% with on-track status. No “budget expired” banner for a budget just created for the current month. |
| **Actual Result** | On **31 May 2025**, opened **Budgets** → **+**. **This month** was selected (period **1 May 2025**–**31 May 2025**). Entered name **Groceries**, limit **$200**, account **Cash**, category **Food & Dining**. Tapped save; save succeeded (budget persisted). Immediately after save, **Groceries** appeared under the **Expired** section on the Budgets tab, not Active. On **Home**, an expired-budget banner referenced **Groceries** instead of an active progress card with **$0 / $200**. Behavior contradicts expected: a current-month budget created on the last day of the month should remain active through end of day 31 May. |
| **Status** | Fail |
| **Post-conditions** | Budget row exists in DB for May 2025 but UI treats it as expired; TC-BUD-002 blocked until active-budget behavior is fixed or dates adjusted. See `docs/testing/phase1-exploration/bug-reports/BUG-001-budget-expired-on-last-day-of-month.md`. |

---

### TC-BUD-002 — Expense in budget category updates progress

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-BUD-002 |
| **Test Title** | Expense in budget category updates progress (decision table: budget + matching category) |
| **Technique Used** | Decision Table (conditions: budget exists × expense category in budget × same period) |
| **Pre-conditions** | TC-BUD-001 complete (**Groceries** / Food / $200); **Cash** account available. |
| **Test Steps** | 1. Note **Groceries** spent amount on Home (baseline).<br>2. Add expense: title **Market run**, amount **50.00**, category **Food**, account **Cash**.<br>3. Return to Home budget section.<br>4. Compare spent total and progress bar vs. baseline. |
| **Test Data** | Expense: `Market run`, `50.00`, category Food; Budget: Groceries $200 |
| **Expected Result** | Blocked |
| **Actual Result** | Not executed; blocked by TC-BUD-001 failure (Groceries budget shown as Expired on last day of month — BUG-001). |
| **Status** | Blocked |
| **Post-conditions** | Budget spent metric includes new expense; transaction also in list. |

---

### TC-ACC-001 — Create second account visible on Home

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-ACC-001 |
| **Test Title** | Create second account and view on Home carousel |
| **Technique Used** | Use Case Testing |
| **Pre-conditions** | **Cash** account exists; Home tab open. |
| **Test Steps** | 1. On Home, scroll account cards horizontally; tap **Add account** (+ card).<br>2. Enter name **Savings**, currency **USD**, balance **1000** (if prompted).<br>3. Save.<br>4. On Home, scroll account carousel; tap **Savings** card to open details.<br>5. Verify name and balance on details screen. |
| **Test Data** | Account name: `Savings`; Currency: `USD`; Opening balance: `1000.00` |
| **Expected Result** | Second account created. Home carousel shows **Cash** and **Savings**. **Savings** details show **$1,000.00** balance. |
| **Actual Result** | On **Home**, scrolled the account carousel and tapped the **Add account** (+) card. Entered name **Savings**, currency **USD**, opening balance **$1,000.00**; saved successfully. Carousel showed **Cash** and **Savings** side by side. Tapped **Savings** account details opened with name **Savings** and balance **$1,000.00**. **Cash** remained at **$499.99** from prior transaction cases. Behavior matched expected second-account creation and display. |
| **Status** | Pass |
| **Post-conditions** | Two accounts in system; **Savings** balance 1000.00. |

---

### TC-ACC-002 — Delete empty account succeeds

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-ACC-002 |
| **Test Title** | Delete account with no transactions succeeds |
| **Technique Used** | State Transition (create empty account → delete → removed from UI) |
| **Pre-conditions** | Create temporary account **Temp Empty** with **$0** and **no transactions** (via Home → Add account). |
| **Test Steps** | 1. From Home, tap **Temp Empty** to open account details.<br>2. Open overflow / menu → **Delete Account** (or trash icon).<br>3. Read confirmation dialog; tap **Delete**.<br>4. Return to Home; search carousel for **Temp Empty**. |
| **Test Data** | Account: `Temp Empty`, balance `0`, zero transactions |
| **Expected Result** | Confirmation warns about deletion. After confirm, success snackbar; navigates back. **Temp Empty** no longer appears on Home. **Cash** / **Savings** unchanged. |
| **Actual Result** | Created **Temp Empty** via Home → **Add account** with **$0.00** balance and no transactions. Opened **Temp Empty** account details, tapped **Delete Account**. Confirmation dialog **“Are you sure you want to delete ‘Temp Empty’?”** appeared; tapped **Delete**. Green snackbar **“Account ‘Temp Empty’ deleted”** displayed; screen navigated back to Home. **Temp Empty** no longer appeared in the account carousel; **Cash** and **Savings** remained visible with balances unchanged. |
| **Status** | Pass |
| **Post-conditions** | **Temp Empty** removed from database; remaining accounts intact. |

---

### TC-ACC-003 — Delete account with transactions blocked

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-ACC-003 |
| **Test Title** | Delete **Cash** account while transactions exist shows error |
| **Technique Used** | Error Guessing (attempt destructive action on non-empty account) |
| **Pre-conditions** | **Cash** has ≥1 transaction; account details reachable. |
| **Test Steps** | 1. Open **Cash** account details.<br>2. Attempt **Delete Account**.<br>3. Confirm delete in dialog if shown.<br>4. Observe result; return to Home and verify **Cash** still present. |
| **Test Data** | Account: Cash (non-empty) |
| **Expected Result** | Either delete is blocked with clear error (e.g. foreign-key / “has associated transactions”) **or** dialog explicitly warns that transactions will be cascade-deleted and user can cancel. If product policy is cascade delete, deletion succeeds only after explicit confirm and transactions removed — document actual behavior. |
| **Actual Result** | Opened **Cash** account details (**Cash** had **Paycheck** and **Penny** transactions from prior TXN cases). Tapped **Delete Account**. Confirmation dialog warned that deletion would also remove associated transactions; tapped **Delete** to confirm. Delete was blocked red snackbar displayed **“Cannot delete: This account has associated transactions”**; remained on account details. Returned to Home **Cash** still present in carousel with balance **$499.99** unchanged. Dialog warns about cascade delete, but deletion is blocked by foreign-key constraint — data integrity preserved. |
| **Status** | Pass |
| **Post-conditions** | Data integrity preserved per actual app policy; note behavior for bug report if unexpected. |

---

### TC-SET-001 — Switch language English to Khmer updates labels

| Field | Detail |
|-------|--------|
| **Test Case ID** | TC-SET-001 |
| **Test Title** | Toggle app language English → Khmer updates navigation labels |
| **Technique Used** | Error Guessing / i18n (locale switch without restart) |
| **Pre-conditions** | App in English; **More** tab accessible. |
| **Test Steps** | 1. Open **More** → **Settings & Customization**.<br>2. Tap **Language**; select **Khmer** (ខ្មែរ).<br>3. Dismiss picker; navigate back to main tabs.<br>4. Read bottom navigation labels (Home, Transactions, Budgets, More equivalents).<br>5. Switch back to **English** and confirm labels revert. |
| **Test Data** | Locales: `en` → `km` → `en` |
| **Expected Result** | After Khmer selection, bottom nav and Settings strings display Khmer script (e.g. home/transactions labels localized). No crash. Switching back to English restores English labels immediately without reinstall. |
| **Actual Result** | Opened **More** → **Settings & Customization** → **Language**; selected **Khmer** (ខ្មែរ) from the picker and dismissed the sheet. Bottom navigation updated immediately to Khmer: **ទំព័រដើម**, **ប្រតិបត្តិការ**, **ថវិកា**, **ច្រើនទៀត**. Settings screen showed **ការកំណត់ និងការប្ដូរតាមបំណង** and **ភាសា** with no crash. Switched back to **English** via the same path; nav labels reverted to **Home**, **Transactions**, **Budgets**, **More** without restart or reinstall. Locale change applied instantly in both directions. |
| **Status** | Pass |
| **Post-conditions** | Locale preference persisted in app settings. |

---

## Execution Summary

| Test Case ID | Status | Notes / Bug link |
|--------------|--------|------------------|
| TC-ONB-001 | Pass | Onboarding + account setup OK; relaunch skips onboarding |
| TC-TXN-001 | Pass | Lunch $15 expense saved; Cash balance −$15.00 |
| TC-TXN-002 | Pass | Paycheck $500 income saved; role split sheet shown and skipped; Cash −$15.00 → $485.00 |
| TC-TXN-003 | Pass | Penny $0.01 expense accepted; Cash $485.00 → $484.99 |
| TC-TXN-004 | Pass | Amount 0 rejected; snackbar “Please enter a valid amount”; balance unchanged at $484.99 |
| TC-TXN-005 | Pass | Lunch $15 expense deleted via swipe; Cash balance $484.99 → $499.99 (+$15.00) |
| TC-BUD-001 | Fail | Last day of month: “This month” budget saved then shown as Expired — BUG-001 |
| TC-BUD-002 | Blocked | Depends on TC-BUD-001 active **Groceries** budget |
| TC-ACC-001 | Pass | Savings account created ($1,000); visible on Home carousel and details |
| TC-ACC-002 | Pass | Temp Empty ($0, no txns) deleted; Cash and Savings unchanged |
| TC-ACC-003 | Pass | Cash delete blocked with “Cannot delete: This account has associated transactions”; account preserved |
| TC-SET-001 | Pass | en → km → en; bottom nav and Settings localized; no restart required |
---