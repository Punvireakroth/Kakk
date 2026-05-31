# Phase 2 — Unit Test Summary

**Project:** Kakk (CashChew)  
**Date:** 2026-05-31  
**Path:** Path B — custom mobile app (Flutter + SQLite)

## Overview

Phase 2 white-box validation covers **19 automated unit tests** across database logic, exchange rates, and currency formatting, plus **10 Postman requests** for external APIs and **2 E2E journeys** in `integration_test/`.

## Test Count by File

| File | Tests | Focus |
|------|------:|-------|
| `test/services/database_service_test.dart` | 9 | Balances, CRUD, date filters, FK behavior, budget spent |
| `test/services/exchange_rate_service_test.dart` | 5 | Same currency, cache, API errors, conversion |
| `test/utils/currency_formatter_test.dart` | 5 | Zero, negative, KHR decimals, parse, symbols |
| **Total unit tests** | **19** | |

## How to Run

```bash
# Unit tests (VM — uses sqflite_common_ffi in-memory DB)
flutter test

# E2E journeys (device/simulator — ~2 min first build)
flutter test integration_test/

# Postman / Newman (requires network; set gemini_api_key locally)
newman run postman/Kakk-External-APIs.postman_collection.json \
  -e postman/Kakk.postman_environment.json
```

### Unit test pass output (sample)

```
flutter test
00:03 +19: All tests passed!
```

### Integration test journeys

| Journey | File | Flow |
|---------|------|------|
| 1 | `integration_test/onboarding_transaction_test.dart` | Onboarding → first expense → verify list |
| 2 | `integration_test/budget_lifecycle_test.dart` | Expense → create budget → verify 20% progress |

## Techniques Used

| Technique | Where applied |
|-----------|---------------|
| **Equivalence partitioning** | Income vs expense categories; valid vs invalid currency codes |
| **Boundary values** | Zero amounts, date-range edges, month-end budget periods |
| **Decision tables** | Balance delta rules (add / update / delete transaction) |
| **Mocking** | `http.MockClient` for exchange rate API (cache hit, 404, error body) |
| **Service-layer CRUD** | `DatabaseService` in-memory tests satisfy Path B “full CRUD” intent |

## Test Infrastructure

- **`test/helpers/test_database.dart`** — `sqfliteFfiInit()`, in-memory DB via `DatabaseService.openInMemoryForTesting()`, seed helpers
- **`@visibleForTesting`** hooks on `DatabaseService` and `ExchangeRateService.testClient`
- **`integration_test/helpers/test_harness.dart`** — app bootstrap, onboarding shortcuts, form helpers

## Postman Collection

| Folder | Requests | Assertions (min 2 each) |
|--------|----------|-------------------------|
| Exchange Rate API | 6 | Status + JSON body fields |
| Gemini API | 4 | Status + `candidates` / `error` |
| **Total** | **10** | |

Files:

- `postman/Kakk-External-APIs.postman_collection.json`
- `postman/Kakk.postman_environment.json` (placeholder keys only — **never commit real secrets**)

## Notes

- **Month-end budgets:** E2E journey 2 exposed BUG-001 (budget `endDate` at midnight on last day). `BudgetFormScreen` now stores end-of-day (`23:59:59.999`) for “This month” / default periods so spending on the last calendar day is counted.
- **Widget keys** added for stable E2E: `fab_add_transaction`, `transaction_category_picker`, `fab_add_budget`, `budget_name_field`, `budget_limit_field`, `budget_submit_button`.

