# Charter: Locale, accessibility, and empty states

- **Charter ID:** CH-05
- **Tester:** QA Team
- **Date / Duration:** 2026-05-31, 45 min
- **Mission:** Explore Khmer/English switching, dynamic text scaling, empty states, and basic screen-reader labels on primary navigation.
- **Scope:**
  - **In:** Settings language picker, bottom navigation, empty Transactions/Budgets lists, iOS **Settings → Display → Larger Text** (simulator).
  - **Out:** Full WCAG audit, Khmer font rendering on Android.
- **Oracles:**
  - Locale change applies without reinstall or crash.
  - Empty states show helpful copy (not blank screens).
  - Large text: no critical label truncation on bottom nav and Home headers.

## Session log

| Time | Action | Observation |
|------|--------|-------------|
| 16:00 | Fresh reset → complete onboarding only (no transactions) | Transactions tab shows empty state with guidance text |
| 16:06 | Open **Budgets** with no budgets | Empty state visible; **+** affordance clear |
| 16:10 | **More → Settings → Language → Khmer (ខ្មែរ)** | Bottom nav: **ទំព័រដើម**, **ប្រតិបត្តិការ**, **ថវិកា**, **ច្រើនទៀត** |
| 16:14 | Navigate all four tabs in Khmer | No mixed-language nav labels; Settings title localized |
| 16:18 | Switch back to **English** | Labels revert immediately — matches **TC-SET-001** |
| 16:22 | iOS Simulator: increase **Dynamic Type** / larger accessibility text | Home welcome line wraps; bottom nav icons still visible |
| 16:28 | At largest text size, open **Transactions → +** | Form fields scroll; Save button reachable |
| 16:32 | Enable **VoiceOver** briefly on Home tab | Bottom nav items announced with tab names (Home/Transactions/etc.) |
| 16:38 | Khmer + large text combined | Khmer script readable; minor truncation on **Settings & Customization** subtitle on small sim width — cosmetic only |
| 16:42 | Relaunch app | Khmer preference persisted |

## Findings

1. **Locale toggle:** Pass — instant switch en ↔ km (also recorded as **TC-SET-001**).
2. **Empty states:** Pass — Transactions and Budgets show empty guidance, not blank lists.
3. **Large text:** Pass with minor cosmetic truncation on long Khmer settings string at extreme sizes.
4. **VoiceOver basics:** Pass — tab bar items reachable and labeled.

## Bugs filed

- None

## Evidence

- `docs/testing/evidence/CH-05-khmer-bottom-nav.png` (optional)

## Follow-up

- Consider shorter Khmer string or ellipsis for **settingsAndCustomization** at AX5 text size (P3 polish)
- Widget test: locale switch updates `AppLocalizations` delegates
