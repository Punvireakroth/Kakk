# Kakk Quality Engineering — Testing Project

These are the overview for our Quality Engineering test. It explains what we are building, where files go, and what “done” looks like for each phase.

| Document | Purpose |
|----------|---------|
| **This README** | Overview, folder map, requirements, templates, team checklist |

**Branch:** `test/test-main`

---

## 1. What This Project Is

We simulate a professional QA lifecycle on **Kakk** — a Flutter personal finance app with local SQLite storage and external HTTP APIs.

| Item | Value |
|------|-------|
| **Course path** | **B — Creator** (our own app from prior coursework) |
| **Frontend** | Flutter / Dart, Material Design 3, Riverpod |
| **Data layer** | SQLite via `DatabaseService` (sqflite) — treat this as our “backend” |
| **External APIs** | Exchange rates (`open.er-api.com`), Gemini AI, Google Sign-In / Drive backup |

### Path B — Important Adaptation

The course assumes a traditional frontend + REST backend. **Kakk has no custom REST server.** We adapt as follows:

| Course requirement | Our approach |
|--------------------|--------------|
| Backend unit tests | Dart unit tests on `DatabaseService`, providers, and services |
| Postman API collection (CRUD) | Postman against **external APIs** the app uses + document **service-layer CRUD** tests in Dart |
| Load test (50 concurrent users) | **50+ concurrent operations** — SQLite stress script and/or k6 on exchange-rate API |

---

## 2. Grading at a Glance

| Phase | Points | Summary |
|-------|--------|---------|
| **Phase 1** — Exploration | 14 | Black-box test cases, exploratory charters, bug reports |
| **Phase 2** — Engineering | 14 | Unit tests, Postman collection, E2E automation |
| **Phase 3** — Performance | 7 | Baseline → load → breaking point + graph |
| **Phase 4** — Presentation | 7 | 10-min slides + live demo |
| **Total** | **40** | |

Optional extra credit: observability dashboard during load tests (Logz.io or similar).

---

## 3. Repository Layout

All QA **documentation** lives under `docs/testing/`. **Code & automation** lives at repo root.

```
docs/testing/
├── README.md                      ← you are here
├── phase1-exploration/
│   ├── app-flow-map.md            ← optional but recommended
│   ├── test-case-suite.md         ← REQUIRED: ≥10 black-box cases
│   ├── charters/                  ← REQUIRED: ≥3 sessions (≥5 for final report)
│   └── bug-reports/               ← REQUIRED: one file per bug
├── phase2-engineering/
│   └── unit-test-summary.md       ← REQUIRED: coverage notes + how to run
├── phase3-performance/
│   ├── performance-analysis-report.md
│   └── graphs/                    ← response-time-vs-load.png, etc.
├── evidence/                      ← screenshots & recordings (linked from bugs/charters)
└── presentation/
    └── slide-outline.md           ← 10-min demo structure

test/                              ← unit & widget tests (≥10)
├── helpers/
├── services/
├── providers/
└── utils/

integration_test/                  ← E2E journeys (≥2)
postman/                           ← collection + environment JSON
tool/stress/                       ← k6 or Dart load scripts
```

---

## 4. Phase Overview

### Phase 1 — Investigate

**Mindset:** User perspective only. **Do not read source code** for test case design or charter sessions.

| Part | Deliverable | Minimum |
|------|-------------|---------|
| **A — Test cases** | `phase1-exploration/test-case-suite.md` | ≥10 cases, happy + sad paths, multiple techniques |
| **B — Charters** | `phase1-exploration/charters/charter-NN-*.md` | ≥3 completed sessions (**≥5** for final written report) |
| **C — Bugs** | `phase1-exploration/bug-reports/BUG-NNN-*.md` + `evidence/` | Every failure from A or B, with screenshots |

**Module coverage for test cases:** onboarding (1), transactions (3+), budgets (2+), accounts (2+), settings/backup (1+).

**Suggested charter missions:**

| ID | Mission |
|----|---------|
| CH-01 | Data integrity — rapid add/edit/delete; verify balances & budget bars |
| CH-02 | Currency & conversion — multi-currency, offline/online |
| CH-03 | Persistence & backup — kill app mid-form, restart, restore |
| CH-04 | External services — Google sign-in cancel, no network, bad API key |
| CH-05 | Locale & accessibility — Khmer/English, large text, empty states |

**App areas to map first (no code):**

| Tab | Flows |
|-----|-------|
| Home | Account selector, budgets/roles, spending graph, recent transactions |
| Transactions | List, filters, swipe actions, add/edit form |
| Budgets | Create/edit, progress indicators |
| More | Accounts, settings, backup, AI roles, locale |

---

### Phase 2 — Engineer

**Mindset:** Verify logic and integrations.

| Part | Location | Minimum |
|------|----------|---------|
| **Unit tests** | `test/` + `phase2-engineering/unit-test-summary.md` | ≥10 tests, happy + sad, all passing |
| **Postman** | `postman/*.json` | ≥10 requests, ≥2 assertions each (status + JSON body) |
| **E2E** | `integration_test/` | ≥2 automated user journeys |

**Priority unit-test targets:**

- `lib/services/database_service.dart` — CRUD, cascades, balance updates
- `lib/providers/transaction_provider.dart`, `account_provider.dart`, `budget_provider.dart`
- `lib/services/exchange_rate_service.dart` — cache, errors, same-currency
- `lib/utils/currency_formatter.dart`

**Required E2E journeys:**

1. **Onboarding → first transaction** — complete setup, add expense, verify on home/list
2. **Budget lifecycle** — create budget, add matching expense, assert progress UI

**Postman scope (external APIs):**

- Exchange rates: `GET https://open.er-api.com/v6/latest/{currency}`
- Gemini API (optional, needs local API key — never commit)
- Google OAuth/Drive (optional, test account)

**Commands:**

```bash
flutter test                          # unit tests
flutter test integration_test/      # E2E (emulator/device required)
newman run postman/Kakk-External-APIs.postman_collection.json \
  -e postman/Kakk.postman_environment.json
```

---

### Phase 3 — Stress

**Goal:** Baseline (1 user) → **≥50 concurrent operations** → increase until failure → report with graph.

| Deliverable | Content |
|-------------|---------|
| `phase3-performance/performance-analysis-report.md` | Environment, methodology, baseline, load results, bottleneck |
| `phase3-performance/graphs/` | Response Time vs Concurrent Operations |
| `tool/stress/` | `db_stress.dart` and/or `k6-exchange.js` |

**Scenarios to measure:** cold start, transaction list at 100+ rows, parallel DB reads/writes, exchange-rate API under load.

---

### Phase 4 — Presentation

**10-minute slides** + **live demo** after slides.

| Slide | Content |
|-------|---------|
| 1 | Title, group, Path B, tech stack |
| 2 | Strategy — how we mapped the app, charter missions / heuristics |
| 3 | **2 best bugs** with screenshots |
| 4 | Postman + unit tests |
| 5 | Performance graph + bottleneck explanation |

**Live demo order:** `flutter test` → Postman/Newman → `flutter test integration_test/` → stress script

Outline: `docs/testing/presentation/slide-outline.md`

---

## 5. Team Workflow

### Getting started (every teammate)

1. Clone repo, checkout `test/test-main`
2. `flutter pub get` && `flutter run` — explore the app once
3. Read this README
4. Install: Flutter SDK, emulator, Postman, k6 (optional)

### Suggested work split

| Owner | Focus | Primary outputs |
|-------|-------|-----------------|
| **Tester A** | Phase 1 — test cases + CH-01, CH-02 | `test-case-suite.md`, 2 charters |
| **Tester B** | Phase 1 — CH-03, CH-04, CH-05 + bugs | 3 charters, `bug-reports/`, `evidence/` |
| **Dev A** | Phase 2 — unit tests | `test/`, `unit-test-summary.md` |
| **Dev B** | Phase 2 — Postman + E2E | `postman/`, `integration_test/` |
| **Anyone** | Phase 3 — performance | `tool/stress/`, performance report + graphs |
| **Whole team** | Phase 4 — slides + demo rehearsal | `presentation/` |

Adjust names and split to your group size. **Phase 1 must finish before Phase 2** (bugs inform unit/E2E priorities).

### Naming conventions

| Artifact | Pattern | Example |
|----------|---------|---------|
| Test case ID | `TC-{MODULE}-{NNN}` | `TC-TXN-001` |
| Charter ID | `CH-{NN}` | `CH-01` |
| Bug ID | `BUG-{NNN}` | `BUG-001` |
| Evidence | `BUG-NNN-step-N.png`, `CH-NN-finding.png` | `evidence/BUG-001-step-2.png` |

### Secrets

- **Never commit** real API keys in Postman env, `.env`, or docs
- Use Postman environment placeholders; each teammate sets keys locally

---

## 6. Progress Tracker

Update checkboxes as the team completes work.

### Phase 1

- [ ] App flow map (`phase1-exploration/app-flow-map.md`)
- [x] Test environment recorded at top of `test-case-suite.md`
- [x] ≥10 black-box test cases written **and executed**
- [x] ≥3 charter logs complete (target **5** for final report) — `charter-01` … `charter-05`
- [x] All failures logged as bug reports with evidence — BUG-001

### Phase 2

- [ ] Test DB helper (`test/helpers/test_database.dart`)
- [ ] ≥10 unit tests passing (`flutter test`)
- [ ] `unit-test-summary.md` complete
- [ ] Postman collection ≥10 requests exported to `postman/`
- [ ] E2E journey 1 — onboarding → transaction
- [ ] E2E journey 2 — budget lifecycle

### Phase 3

- [ ] Baseline metrics recorded
- [ ] Load test ≥50 concurrent operations
- [ ] Breaking point identified
- [ ] Graph saved to `phase3-performance/graphs/`
- [ ] `performance-analysis-report.md` complete

### Phase 4 & submission

- [ ] Slide deck + `slide-outline.md`
- [ ] Demo rehearsed (unit → Postman → E2E → performance)
- [ ] GitHub repo link ready (tests + Postman committed)
- [ ] No secrets in repo

---

## 7. Suggested Timeline

| Week | Focus |
|------|-------|
| 1 | Phase 1 — flow map, test cases, charters CH-01–02 |
| 2 | Phase 1 — charters CH-03–05, execute all cases, bug reports |
| 3 | Phase 2 — unit tests + Postman |
| 4 | Phase 2 E2E + Phase 3 performance |
| 5 | Presentation + final report assembly |

Adjust to your course deadline.

---

## 8. Templates

Use these fields for every artifact. Official PDF templates: [Project_Testing_Guidlines.pdf](../Project_Testing_Guidlines.pdf) pages 4–5.

### Test case → `phase1-exploration/test-case-suite.md`

| Field | Example |
|-------|---------|
| Test Case ID | `TC-TXN-001` |
| Test Title | Add valid expense updates account balance |
| Technique Used | Use Case Testing |
| Pre-conditions | User on Transactions screen; Cash account exists |
| Test Steps | 1. Tap + 2. Enter amount 10.00 3. Save |
| Test Data | Amount: 10.00, Category: Food |
| Expected Result | Balance decreases by 10; transaction appears in list |
| Actual Result | *(fill during run)* |
| Status | Pass / Fail / Blocked |
| Post-conditions | New transaction persisted after app restart |

**Techniques to mix:** Equivalence Partitioning, Boundary Value Analysis, Decision Table, State Transition, Error Guessing, Use Case Testing.

### Bug report → `phase1-exploration/bug-reports/BUG-NNN-title.md`

| Field | Content |
|-------|---------|
| Bug ID | `BUG-001` |
| Title | Short, specific summary |
| Description | Impact in 1–2 sentences |
| Severity / Priority | e.g. Major / P2 |
| Environment | iOS 18 sim, Kakk 1.0.0, en locale |
| Steps to Reproduce | Numbered steps |
| Expected Result | What should happen |
| Actual Result | What happened |
| Evidence | `../evidence/BUG-001.png` |
| Discovery | Charter CH-02 or Test Case TC-TXN-003 |
| Status | New / Open / Fixed / Verified |

### Charter → `phase1-exploration/charters/charter-01-mission-name.md`

```markdown
# Charter: [Mission Title]
- **Charter ID:** CH-01
- **Tester:** [Name]
- **Date / Duration:** YYYY-MM-DD, 60 min
- **Mission:** Explore [area] to discover [risk type]
- **Scope:** In: … | Out: …
- **Oracles:** Balance math, error messages, data after restart
- **Session log:** (timestamped notes)
- **Bugs filed:** BUG-xxx
- **Follow-up:** New tests or charters
```

---

## 9. Commands Cheat Sheet

```bash
# App
flutter pub get
flutter run

# Tests
flutter test
flutter test integration_test/

# Postman CLI (after collection exists)
newman run postman/Kakk-External-APIs.postman_collection.json \
  -e postman/Kakk.postman_environment.json

# Performance (after scripts exist)
k6 run tool/stress/k6-exchange.js
dart run tool/stress/db_stress.dart
```

---

## 10. Final Submission Checklist

Before submitting the **Software Quality Engineering Report** and presenting:

| # | Deliverable | Location | Requirement |
|---|-------------|----------|-------------|
| 1 | Black-box test suite | `phase1-exploration/test-case-suite.md` | ≥10 cases |
| 2 | Charter logs | `phase1-exploration/charters/` | ≥5 charters |
| 3 | Bug tracking log | `phase1-exploration/bug-reports/` | All failures documented |
| 4 | Unit tests + summary | `test/` + `phase2-engineering/unit-test-summary.md` | ≥10 passing |
| 5 | Postman collection | `postman/*.json` | ≥10 requests, 2+ assertions each |
| 6 | E2E automation | `integration_test/` | ≥2 journeys |
| 7 | Performance report | `phase3-performance/performance-analysis-report.md` | Graph + bottleneck |
| 8 | GitHub repo | Remote link | Tests + Postman in repo |
| 9 | Secrets hygiene | — | No API keys committed |

---