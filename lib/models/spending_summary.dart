import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../utils/currency_formatter.dart';

/// Aggregated expense history for AI role suggestions 
@immutable
class SpendingSummary {
  const SpendingSummary({
    required this.averageNeeds,
    required this.averageWants,
    required this.averageGoals,
    required this.activeGoals,
    required this.incomeAmount,
    required this.periodStart,
    required this.periodEnd,
    required this.hasMinimumExpenseHistoryForAi,
    this.currencyCode = 'USD',
  });

  /// Average monthly spending attributed to Needs (from categorized expenses).
  final double averageNeeds;

  /// Average monthly spending attributed to Wants.
  final double averageWants;

  /// Average monthly spending attributed to Goals (50/30/20 "savings" bucket).
  final double averageGoals;

  /// Named savings goals — Phase 4; empty until goals exist.
  final List<String> activeGoals;

  /// Income amount the user is assigning to roles in this flow.
  final double incomeAmount;

  final DateTime periodStart;
  final DateTime periodEnd;

  /// At least ~28 days between earliest and latest expense in the analysis window.
  final bool hasMinimumExpenseHistoryForAi;

  final String currencyCode;

  /// Text for the AI provider: aggregates only — no transaction titles or notes.
  String get structuredPrompt {
    final dateFmt = DateFormat.yMMMd();
    final cc = currencyCode;
    String fmt(double v) => CurrencyFormatter.format(v, currency: cc);
    final goalsLine = activeGoals.isEmpty
        ? 'Active savings goals: none recorded.'
        : 'Active savings goals: ${activeGoals.length} (labels only; no amounts).';

    return '''
User is assigning income to three budget roles: Needs, Wants, and Goals.

Analysis window (local dates): ${dateFmt.format(periodStart)} – ${dateFmt.format(periodEnd)}.

Income amount to allocate now: ${fmt(incomeAmount)} ($cc).

Historic expense pattern from this window: approximate average monthly spending already grouped by the app's Needs / Wants / Savings category mapping — Needs: ${fmt(averageNeeds)}, Wants: ${fmt(averageWants)}, Goals (savings-style spending): ${fmt(averageGoals)}. Values are rolled-up totals from expense transactions only; individual purchases are not listed.

$goalsLine

Propose how to split the income amount across Needs, Wants, and Goals for this assignment. Keep rationales high-level; do not infer specific merchants or purchases.
'''.trim();
  }
}
