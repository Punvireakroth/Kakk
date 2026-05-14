import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import '../utils/budget_role_type.dart';
import '../utils/budget_rule_categories.dart';

/// How to handle unspent funds when a role budget period ends.
enum RoleRolloverDestination {
  /// Keep as the same role next period (limit = leftover).
  carryForward,

  /// Add leftover to the Goals bucket for the next period (Needs/Wants only).
  moveToGoals,
}

/// Expired role budgets with unspent balance, newest periods first.
List<BudgetWithSpent> expiredRoleBudgetsWithRemaining(
  List<BudgetWithSpent> expired,
) {
  int roleSort(BudgetRoleType? r) => switch (r) {
        BudgetRoleType.needs => 0,
        BudgetRoleType.wants => 1,
        BudgetRoleType.goals => 2,
        _ => 3,
      };
  final list = expired
      .where(
        (b) => b.budget.roleType != null && b.remaining > 0.009,
      )
      .toList()
    ..sort((a, b) {
      final byRole =
          roleSort(a.budget.roleType).compareTo(roleSort(b.budget.roleType));
      if (byRole != 0) return byRole;
      return b.budget.endDate.compareTo(a.budget.endDate);
    });
  return list;
}

/// Data class to hold budget with its spending info
class BudgetWithSpent {
  final Budget budget;
  final List<String> categoryIds;
  final double spent;
  final double remaining;
  final double percentage;
  final int daysRemaining;
  final double dailyAllowance;

  const BudgetWithSpent({
    required this.budget,
    required this.categoryIds,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.daysRemaining,
    required this.dailyAllowance,
  });

  bool get isOverBudget => percentage > 100;
  bool get isWarning => percentage >= 80 && percentage <= 100;
  bool get isOnTrack => percentage < 80;
}

/// State class for budget management
class BudgetState {
  final List<BudgetWithSpent> budgets;
  final List<BudgetWithSpent> archivedBudgets;
  final bool isLoading;
  final String? error;

  const BudgetState({
    this.budgets = const [],
    this.archivedBudgets = const [],
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    List<BudgetWithSpent>? budgets,
    List<BudgetWithSpent>? archivedBudgets,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      archivedBudgets: archivedBudgets ?? this.archivedBudgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get only active budgets (current period, not archived)
  List<BudgetWithSpent> get activeBudgets {
    final now = DateTime.now().millisecondsSinceEpoch;
    return budgets.where((b) {
      return b.budget.startDate <= now &&
          b.budget.endDate >= now &&
          !b.budget.isArchived;
    }).toList();
  }

  /// Get expired but not archived budgets
  List<BudgetWithSpent> get expiredBudgets {
    final now = DateTime.now().millisecondsSinceEpoch;
    return budgets.where((b) {
      return b.budget.endDate < now && !b.budget.isArchived;
    }).toList();
  }

  /// Get future budgets (not started yet, not archived)
  List<BudgetWithSpent> get futureBudgets {
    final now = DateTime.now().millisecondsSinceEpoch;
    return budgets.where((b) {
      return b.budget.startDate > now && !b.budget.isArchived;
    }).toList();
  }

  /// Loaded non-archived budgets that were created from the role split (Needs / Wants / Goals).
  List<BudgetWithSpent> get roleBudgets =>
      budgets.where((b) => b.budget.roleType != null).toList();

  /// Per-day discretionary room from the **active** [BudgetRoleType.wants] budget.
  /// Matches [BudgetWithSpent.remaining] / [BudgetWithSpent.daysRemaining] (see [BudgetWithSpent.dailyAllowance]).
  double? get safeToSpendToday {
    final wants = activeBudgets
        .where((b) => b.budget.roleType == BudgetRoleType.wants)
        .firstOrNull;
    return wants?.dailyAllowance;
  }
}

/// Budget provider using Riverpod StateNotifier
class BudgetNotifier extends StateNotifier<BudgetState> {
  final DatabaseService _db;

  BudgetNotifier(this._db) : super(const BudgetState());

  /// Load all budgets with their spending info from database
  Future<void> loadBudgets() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load non-archived budgets
      final budgets = await _db.getNonArchivedBudgets();
      final budgetsWithSpent = await _processBudgets(budgets);

      // Load archived budgets
      final archived = await _db.getArchivedBudgets();
      final archivedWithSpent = await _processBudgets(archived);

      state = state.copyWith(
        budgets: budgetsWithSpent,
        archivedBudgets: archivedWithSpent,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load budgets: ${e.toString()}',
      );
    }
  }

  /// Process a list of budgets to add spending info
  Future<List<BudgetWithSpent>> _processBudgets(List<Budget> budgets) async {
    final budgetsWithSpent = <BudgetWithSpent>[];

    for (final budget in budgets) {
      // Get categories linked to this budget
      final categoryIds = await _db.getBudgetCategoryIds(budget.id);

      // Calculate spent amount based on linked categories and account
      final spent = categoryIds.isEmpty
          ? 0.0
          : await _db.getBudgetSpent(
              budget.startDate,
              budget.endDate,
              categoryIds,
              accountId: budget.accountId,
            );

      final remaining = budget.limitAmount - spent;
      final percentage = budget.limitAmount > 0
          ? (spent / budget.limitAmount) * 100
          : 0.0;

      // Calculate days remaining
      final now = DateTime.now();
      final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
      final daysRemaining = endDate.difference(now).inDays;

      // Calculate daily allowance
      final dailyAllowance = daysRemaining > 0
          ? remaining / daysRemaining
          : 0.0;

      budgetsWithSpent.add(
        BudgetWithSpent(
          budget: budget,
          categoryIds: categoryIds,
          spent: spent,
          remaining: remaining > 0 ? remaining : 0,
          percentage: percentage,
          daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
          dailyAllowance: dailyAllowance > 0 ? dailyAllowance : 0,
        ),
      );
    }

    return budgetsWithSpent;
  }

  /// Create a new budget with linked categories
  Future<bool> createBudget(Budget budget, List<String> categoryIds) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if budget name already exists
      final exists = await _db.budgetExistsByName(budget.name);
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A budget with this name already exists',
        );
        return false;
      }

      // Validate at least one category
      if (categoryIds.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please select at least one category',
        );
        return false;
      }

      await _db.insertBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);

      // Reload budgets to get updated list with spending info
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update an existing budget with linked categories
  Future<bool> updateBudget(Budget budget, List<String> categoryIds) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if budget name exists (excluding current budget)
      final exists = await _db.budgetExistsByName(
        budget.name,
        excludeId: budget.id,
      );
      if (exists) {
        state = state.copyWith(
          isLoading: false,
          error: 'A budget with this name already exists',
        );
        return false;
      }

      // Validate at least one category
      if (categoryIds.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please select at least one category',
        );
        return false;
      }

      await _db.updateBudget(budget);
      await _db.setBudgetCategories(budget.id, categoryIds);

      // Reload budgets to get updated list
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get category IDs for a budget
  Future<List<String>> getBudgetCategoryIds(String budgetId) async {
    return await _db.getBudgetCategoryIds(budgetId);
  }

  /// Delete a budget by id
  Future<bool> deleteBudget(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.deleteBudget(id);

      // Reload budgets to get updated list
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Archive a budget
  Future<bool> archiveBudget(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.archiveBudget(id);
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to archive budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Restore an archived budget
  Future<bool> restoreBudget(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _db.restoreBudget(id);
      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to restore budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Renew a budget for the next period
  Future<bool> renewBudget(
    BudgetWithSpent oldBudget, {
    required int newStartDate,
    required int newEndDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Archive the old budget
      await _db.archiveBudget(oldBudget.budget.id);

      // Create a new budget with the same settings but new dates
      final now = DateTime.now().millisecondsSinceEpoch;
      final newBudget = Budget(
        id: '${oldBudget.budget.id}_renewed_$now',
        name: oldBudget.budget.name,
        accountId: oldBudget.budget.accountId,
        limitAmount: oldBudget.budget.limitAmount,
        startDate: newStartDate,
        endDate: newEndDate,
        roleType: oldBudget.budget.roleType,
        createdAt: now,
        updatedAt: now,
      );

      await _db.insertBudget(newBudget);
      await _db.setBudgetCategories(newBudget.id, oldBudget.categoryIds);

      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to renew budget: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get a budget by id
  BudgetWithSpent? getBudgetById(String id) {
    try {
      return state.budgets.firstWhere((b) => b.budget.id == id);
    } catch (e) {
      // Check archived budgets too
      try {
        return state.archivedBudgets.firstWhere((b) => b.budget.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Whether non-archived role budgets exist for all three roles overlapping [periodStartMs]–[periodEndMs].
  Future<bool> hasActiveRoleBudgetTrioForPeriod({
    required int periodStartMs,
    required int periodEndMs,
  }) async {
    final budgets = await _db.getNonArchivedBudgets();
    final roles = <BudgetRoleType>{};
    for (final b in budgets) {
      if (b.roleType == null) continue;
      final overlaps =
          b.startDate <= periodEndMs && b.endDate >= periodStartMs;
      if (overlaps) roles.add(b.roleType!);
    }
    return roles.contains(BudgetRoleType.needs) &&
        roles.contains(BudgetRoleType.wants) &&
        roles.contains(BudgetRoleType.goals);
  }

  /// Same as [hasActiveRoleBudgetTrioForPeriod] for the current calendar month.
  Future<bool> hasActiveRoleBudgetTrioForCurrentPeriod() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    return hasActiveRoleBudgetTrioForPeriod(
      periodStartMs: start,
      periodEndMs: end,
    );
  }

  /// Create or extend role-tagged budgets (Needs / Wants / Goals) for [startDate]–[endDate].
  ///
  /// If a non-archived budget with the same [BudgetRoleType] already overlaps that period,
  /// its [Budget.limitAmount] is increased by the split amount; otherwise a new slice is inserted.
  Future<bool> createRoleBudgets({
    required String? accountId,
    required double incomeAmount,
    required double needs,
    required double wants,
    required double goals,
    required int startDate,
    required int endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final total = needs + wants + goals;
      if ((total - incomeAmount).abs() > 0.02) {
        state = state.copyWith(
          isLoading: false,
          error: 'Assigned amounts must equal your income',
        );
        return false;
      }

      final expenseCategories = await _db.getCategories(type: 'expense');
      final categorized =
          BudgetRuleCategorizer.categorizeExpenses(expenseCategories);
      final needsIds =
          categorized[BudgetRuleType.needs]!.map((c) => c.id).toList();
      final wantsIds =
          categorized[BudgetRuleType.wants]!.map((c) => c.id).toList();
      final savingsIds =
          categorized[BudgetRuleType.savings]!.map((c) => c.id).toList();

      final now = DateTime.now().millisecondsSinceEpoch;
      final uuid = const Uuid();
      final periodLabel = DateFormat(
        'MMM yyyy',
      ).format(DateTime.fromMillisecondsSinceEpoch(startDate));

      var workingBudgets = await _db.getNonArchivedBudgets();

      Budget? overlappingRoleBudget(BudgetRoleType role) {
        final matches = workingBudgets.where((b) {
          if (b.roleType != role) return false;
          return b.startDate <= endDate && b.endDate >= startDate;
        }).toList();
        if (matches.isEmpty) return null;
        for (final b in matches) {
          if (b.startDate == startDate && b.endDate == endDate) return b;
        }
        matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return matches.first;
      }

      Future<void> upsertRoleSlice({
        required BudgetRoleType role,
        required double amount,
        required List<String> categoryIds,
      }) async {
        if (amount <= 0) return;
        if (categoryIds.isEmpty) {
          throw Exception(
            'No expense categories for ${role.displayName}. Add expense categories first.',
          );
        }
        final existing = overlappingRoleBudget(role);
        if (existing != null) {
          final updated = existing.copyWith(
            limitAmount: existing.limitAmount + amount,
            updatedAt: now,
          );
          await _db.updateBudget(updated);
          final i = workingBudgets.indexWhere((b) => b.id == existing.id);
          if (i >= 0) workingBudgets[i] = updated;
          return;
        }
        final budget = Budget(
          id: uuid.v4(),
          name: '${role.displayName} · $periodLabel',
          accountId: accountId,
          limitAmount: amount,
          startDate: startDate,
          endDate: endDate,
          roleType: role,
          createdAt: now,
          updatedAt: now,
        );
        await _db.insertBudget(budget);
        await _db.setBudgetCategories(budget.id, categoryIds);
        workingBudgets.add(budget);
      }

      await upsertRoleSlice(
        role: BudgetRoleType.needs,
        amount: needs,
        categoryIds: needsIds,
      );
      await upsertRoleSlice(
        role: BudgetRoleType.wants,
        amount: wants,
        categoryIds: wantsIds,
      );
      await upsertRoleSlice(
        role: BudgetRoleType.goals,
        amount: goals,
        categoryIds: savingsIds,
      );

      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  (DateTime, DateTime) _calendarMonthAfterBudgetEnd(Budget budget) {
    final end = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final nextStart = DateTime(end.year, end.month + 1, 1);
    final nextEnd = DateTime(
      nextStart.year,
      nextStart.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
    return (nextStart, nextEnd);
  }

  Future<Budget?> _findOverlappingRoleBudget({
    required BudgetRoleType role,
    required int periodStartMs,
    required int periodEndMs,
    required String? accountId,
  }) async {
    final budgets = await _db.getNonArchivedBudgets();
    for (final b in budgets) {
      if (b.roleType != role) continue;
      if (b.accountId != accountId) continue;
      final overlaps = b.startDate <= periodEndMs && b.endDate >= periodStartMs;
      if (overlaps) return b;
    }
    return null;
  }

  Future<void> _carryForwardRoleBudgetSlice(
    BudgetWithSpent old,
    Uuid uuid,
    int nowMs,
  ) async {
    final role = old.budget.roleType!;
    final (nextStart, nextEnd) = _calendarMonthAfterBudgetEnd(old.budget);
    final startMs = nextStart.millisecondsSinceEpoch;
    final endMs = nextEnd.millisecondsSinceEpoch;

    await _db.archiveBudget(old.budget.id);

    final existing = await _findOverlappingRoleBudget(
      role: role,
      periodStartMs: startMs,
      periodEndMs: endMs,
      accountId: old.budget.accountId,
    );

    if (existing != null) {
      await _db.updateBudget(
        existing.copyWith(
          limitAmount: existing.limitAmount + old.remaining,
          updatedAt: nowMs,
        ),
      );
      return;
    }

    final periodLabel = DateFormat(
      'MMM yyyy',
    ).format(nextStart);
    final newBudget = Budget(
      id: uuid.v4(),
      name: '${role.displayName} · $periodLabel',
      accountId: old.budget.accountId,
      limitAmount: old.remaining,
      startDate: startMs,
      endDate: endMs,
      roleType: role,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
    await _db.insertBudget(newBudget);
    await _db.setBudgetCategories(newBudget.id, old.categoryIds);
  }

  Future<void> _moveRoleLeftoverToGoalsSlice(
    BudgetWithSpent old,
    Uuid uuid,
    int nowMs,
  ) async {
    final (nextStart, nextEnd) = _calendarMonthAfterBudgetEnd(old.budget);
    final startMs = nextStart.millisecondsSinceEpoch;
    final endMs = nextEnd.millisecondsSinceEpoch;

    await _db.archiveBudget(old.budget.id);

    final existingGoals = await _findOverlappingRoleBudget(
      role: BudgetRoleType.goals,
      periodStartMs: startMs,
      periodEndMs: endMs,
      accountId: old.budget.accountId,
    );

    if (existingGoals != null) {
      await _db.updateBudget(
        existingGoals.copyWith(
          limitAmount: existingGoals.limitAmount + old.remaining,
          updatedAt: nowMs,
        ),
      );
      return;
    }

    final expenseCategories = await _db.getCategories(type: 'expense');
    final categorized =
        BudgetRuleCategorizer.categorizeExpenses(expenseCategories);
    final savingsIds =
        categorized[BudgetRuleType.savings]!.map((c) => c.id).toList();
    if (savingsIds.isEmpty) {
      throw Exception(
        'No savings categories for Goals. Add categories first.',
      );
    }

    final periodLabel = DateFormat('MMM yyyy').format(nextStart);
    final newBudget = Budget(
      id: uuid.v4(),
      name: '${BudgetRoleType.goals.displayName} · $periodLabel',
      accountId: old.budget.accountId,
      limitAmount: old.remaining,
      startDate: startMs,
      endDate: endMs,
      roleType: BudgetRoleType.goals,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
    await _db.insertBudget(newBudget);
    await _db.setBudgetCategories(newBudget.id, savingsIds);
  }

  /// Apply end-of-period choices for expired role budgets with leftover funds.
  Future<bool> applyRoleRollovers(
    Map<String, RoleRolloverDestination> choicesByBudgetId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final uuid = const Uuid();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final entry in choicesByBudgetId.entries) {
        final budgetId = entry.key;
        final dest = entry.value;
        final bw = getBudgetById(budgetId);
        if (bw == null) continue;
        final role = bw.budget.roleType;
        if (role == null) continue;
        if (bw.remaining <= 0.009) continue;
        if (bw.budget.endDate >= now) continue;

        final effective = (role == BudgetRoleType.goals ||
                role == BudgetRoleType.futureMe ||
                role == BudgetRoleType.custom)
            ? RoleRolloverDestination.carryForward
            : dest;

        if (effective == RoleRolloverDestination.moveToGoals) {
          await _moveRoleLeftoverToGoalsSlice(bw, uuid, nowMs);
        } else {
          await _carryForwardRoleBudgetSlice(bw, uuid, nowMs);
        }
      }

      await loadBudgets();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Whether any expired role budget still has unspent balance (reload budgets first).
  bool checkRolloverNeeded() {
    return expiredRoleBudgetsWithRemaining(state.expiredBudgets).isNotEmpty;
  }
}

/// Provider for BudgetNotifier
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>(
  (ref) => BudgetNotifier(DatabaseService()),
);

/// Convenience provider for active budgets count
final activeBudgetsCountProvider = Provider<int>((ref) {
  final state = ref.watch(budgetProvider);
  return state.activeBudgets.length;
});

/// Convenience provider for first active budget (for home screen display)
final primaryBudgetProvider = Provider<BudgetWithSpent?>((ref) {
  final state = ref.watch(budgetProvider);
  final active = state.activeBudgets;
  return active.isNotEmpty ? active.first : null;
});

/// Convenience provider for expired budgets count
final expiredBudgetsCountProvider = Provider<int>((ref) {
  final state = ref.watch(budgetProvider);
  return state.expiredBudgets.length;
});

/// Convenience provider for expired budgets (for renewal prompts)
final expiredBudgetsProvider = Provider<List<BudgetWithSpent>>((ref) {
  final state = ref.watch(budgetProvider);
  return state.expiredBudgets;
});

/// Convenience provider for archived budgets
final archivedBudgetsProvider = Provider<List<BudgetWithSpent>>((ref) {
  final state = ref.watch(budgetProvider);
  return state.archivedBudgets;
});

/// True when Needs, Wants, and Goals role budgets overlap the current date.
final hasActiveRoleBudgetTrioProvider = Provider<bool>((ref) {
  final roles = <BudgetRoleType>{};
  for (final b in ref.watch(budgetProvider).activeBudgets) {
    final r = b.budget.roleType;
    if (r != null) roles.add(r);
  }
  return roles.contains(BudgetRoleType.needs) &&
      roles.contains(BudgetRoleType.wants) &&
      roles.contains(BudgetRoleType.goals);
});

/// Role-tagged budgets (non-archived list from [BudgetState.budgets]).
final roleBudgetsProvider = Provider<List<BudgetWithSpent>>((ref) {
  return ref.watch(budgetProvider).roleBudgets;
});

/// Safe-to-spend-today from the active Wants role budget, if any.
final safeToSpendTodayProvider = Provider<double?>((ref) {
  return ref.watch(budgetProvider).safeToSpendToday;
});

/// Expired role-tagged budgets with leftover balance (rollover candidates).
final expiredRoleRolloverCandidatesProvider =
    Provider<List<BudgetWithSpent>>((ref) {
  final expired = ref.watch(budgetProvider).expiredBudgets;
  return expiredRoleBudgetsWithRemaining(expired);
});
