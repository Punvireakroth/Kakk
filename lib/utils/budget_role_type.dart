import 'package:flutter/material.dart';

import 'budget_rule_categories.dart';

/// Role every dollar can play (50/30/20-style budgeting and extensions).
enum BudgetRoleType {
  needs,
  wants,
  goals,
  futureMe,
  custom,
}

extension BudgetRoleTypeX on BudgetRoleType {
  /// Persisted in SQLite column `budgets.role_type`.
  String get storageValue => switch (this) {
        BudgetRoleType.needs => 'needs',
        BudgetRoleType.wants => 'wants',
        BudgetRoleType.goals => 'goals',
        BudgetRoleType.futureMe => 'future_me',
        BudgetRoleType.custom => 'custom',
      };

  String get displayName => switch (this) {
        BudgetRoleType.needs => 'Needs',
        BudgetRoleType.wants => 'Wants',
        BudgetRoleType.goals => 'Goals',
        BudgetRoleType.futureMe => 'Future Me',
        BudgetRoleType.custom => 'Custom',
      };

  Color get color => switch (this) {
        BudgetRoleType.needs => const Color(0xFF2196F3),
        BudgetRoleType.wants => const Color(0xFF9C27B0),
        BudgetRoleType.goals => const Color(0xFF4CAF50),
        BudgetRoleType.futureMe => const Color(0xFFFF9800),
        BudgetRoleType.custom => const Color(0xFF607D8B),
      };

  IconData get icon => switch (this) {
        BudgetRoleType.needs => Icons.home_outlined,
        BudgetRoleType.wants => Icons.star_outline,
        BudgetRoleType.goals => Icons.flag_outlined,
        BudgetRoleType.futureMe => Icons.update,
        BudgetRoleType.custom => Icons.tune,
      };
}

/// Deserialize [BudgetRoleType] from DB; unknown or empty values yield null.
BudgetRoleType? budgetRoleTypeFromStorage(String? value) {
  if (value == null || value.isEmpty) return null;
  return switch (value) {
    'needs' => BudgetRoleType.needs,
    'wants' => BudgetRoleType.wants,
    'goals' => BudgetRoleType.goals,
    'future_me' => BudgetRoleType.futureMe,
    'custom' => BudgetRoleType.custom,
    _ => null,
  };
}

/// Maps 50/30/20 bucket types to role types ([BudgetRuleType.savings] → [BudgetRoleType.goals]).
BudgetRoleType budgetRoleTypeFromRuleType(BudgetRuleType rule) => switch (rule) {
      BudgetRuleType.needs => BudgetRoleType.needs,
      BudgetRuleType.wants => BudgetRoleType.wants,
      BudgetRuleType.savings => BudgetRoleType.goals,
    };

/// Inverse mapping for the three rule buckets; [futureMe] / [custom] have no rule twin.
BudgetRuleType? budgetRuleTypeFromRoleType(BudgetRoleType role) => switch (role) {
      BudgetRoleType.needs => BudgetRuleType.needs,
      BudgetRoleType.wants => BudgetRuleType.wants,
      BudgetRoleType.goals => BudgetRuleType.savings,
      BudgetRoleType.futureMe || BudgetRoleType.custom => null,
    };
