import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/spending_summary.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../services/database_service.dart';
import '../utils/budget_role_type.dart';
import '../utils/budget_rule_categories.dart';

/// Builds [SpendingSummary] from recent expense history for the AI role assistant.
class SpendingSummaryService {
  SpendingSummaryService._();

  static const int _monthsInWindow = 3;

  /// Loads expense transactions for the last three calendar months (including the
  /// partial current month), maps categories with [BudgetRuleCategorizer], and
  /// returns per-role monthly averages plus [SpendingSummary.structuredPrompt].
  ///
  /// [ref] is used for [categoryProvider]; if categories are not loaded yet,
  /// expense categories are read from [DatabaseService] instead.
  ///
  /// Transaction rows always come from [DatabaseService.getFilteredTransactions]
  /// (same backing store as [transactionProvider]) so the window is complete,
  /// not limited to the provider's paginated page.
  static Future<SpendingSummary> build(
    WidgetRef ref, {
    required double incomeAmount,
    String currencyCode = 'USD',
    DateTime? clock,
  }) async {
    final now = clock ?? DateTime.now();
    final periodStart = DateTime(now.year, now.month - 2, 1);
    final periodEnd = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    );

    final db = DatabaseService();

    final transactions = await db.getFilteredTransactions(
      startDate: periodStart.millisecondsSinceEpoch,
      endDate: periodEnd.millisecondsSinceEpoch,
      type: 'expense',
    );

    var expenseCategories = ref
        .read(categoryProvider)
        .categories
        .where((c) => c.isExpense)
        .toList();
    if (expenseCategories.isEmpty) {
      expenseCategories = await db.getCategories(type: 'expense');
    }

    final categoryRole = _categoryIdToRole(expenseCategories);

    var totalNeeds = 0.0;
    var totalWants = 0.0;
    var totalGoals = 0.0;

    for (final tx in transactions) {
      final role = categoryRole[tx.categoryId] ?? BudgetRoleType.wants;
      switch (role) {
        case BudgetRoleType.needs:
          totalNeeds += tx.amount;
        case BudgetRoleType.wants:
          totalWants += tx.amount;
        case BudgetRoleType.goals:
          totalGoals += tx.amount;
        case BudgetRoleType.futureMe:
        case BudgetRoleType.custom:
          totalWants += tx.amount;
      }
    }

    final historyOk = _hasMinimumExpenseHistory(transactions);

    return SpendingSummary(
      averageNeeds: totalNeeds / _monthsInWindow,
      averageWants: totalWants / _monthsInWindow,
      averageGoals: totalGoals / _monthsInWindow,
      activeGoals: const [],
      incomeAmount: incomeAmount,
      periodStart: periodStart,
      periodEnd: periodEnd,
      hasMinimumExpenseHistoryForAi: historyOk,
      currencyCode: currencyCode,
    );
  }

  /// Expense dates span at least 28 days — proxy for "about one month" of history.
  static bool _hasMinimumExpenseHistory(List<Transaction> expenseTransactions) {
    if (expenseTransactions.length < 2) return false;
    var minMs = expenseTransactions.first.date;
    var maxMs = minMs;
    for (final tx in expenseTransactions) {
      final d = tx.date;
      if (d < minMs) minMs = d;
      if (d > maxMs) maxMs = d;
    }
    return (maxMs - minMs) >= const Duration(days: 28).inMilliseconds;
  }

  static Map<String, BudgetRoleType> _categoryIdToRole(
    List<Category> expenseCategories,
  ) {
    final grouped = BudgetRuleCategorizer.categorizeExpenses(expenseCategories);
    final map = <String, BudgetRoleType>{};
    for (final entry in grouped.entries) {
      final role = budgetRoleTypeFromRuleType(entry.key);
      for (final cat in entry.value) {
        map[cat.id] = role;
      }
    }
    return map;
  }
}
