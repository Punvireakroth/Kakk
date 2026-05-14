import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/budget_role_type.dart';
import '../../../utils/currency_formatter.dart';
import '../../budgets/budget_form_screen.dart';
import '../../budgets/budgets_screen.dart';
import 'budget_expired_banner.dart';

/// Needs / Wants / Goals home block: **% budget left**, **days left**, and one combined
/// timeline bar (period + Today pin + colored fill = budget runway left).
class RoleProgressSection extends ConsumerWidget {
  const RoleProgressSection({super.key});

  static BudgetWithSpent? _activeRole(
    BudgetState state,
    BudgetRoleType role,
  ) {
    return state.activeBudgets
        .where((b) => b.budget.roleType == role)
        .firstOrNull;
  }

  static String _roleTitle(BudgetRoleType role, AppLocalizations l10n) {
    return switch (role) {
      BudgetRoleType.needs => l10n.needs,
      BudgetRoleType.wants => l10n.wants,
      BudgetRoleType.goals => l10n.goals,
      _ => role.displayName,
    };
  }

  /// Traffic light vs **spent** share of budget (same thresholds as elsewhere).
  static Color _usageColor(double spentFractionOfLimit) {
    if (spentFractionOfLimit < 0.8) return const Color(0xFF43A047);
    if (spentFractionOfLimit <= 1.0) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final budgetState = ref.watch(budgetProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;

    final needs = _activeRole(budgetState, BudgetRoleType.needs);
    final wants = _activeRole(budgetState, BudgetRoleType.wants);
    final goals = _activeRole(budgetState, BudgetRoleType.goals);

    final accounts = ref.watch(accountProvider).accounts;
    final currency =
        accounts.isNotEmpty ? accounts.first.currency : 'USD';
    final safeDaily = ref.watch(safeToSpendTodayProvider);

    final barRows = <Widget>[];
    void gap() {
      if (barRows.isNotEmpty) barRows.add(const SizedBox(height: 16));
    }

    if (needs != null) {
      barRows.add(_RoleBudgetGlanceRow(
        accentColor: accentColor,
        l10n: l10n,
        role: BudgetRoleType.needs,
        data: needs,
        label: _roleTitle(BudgetRoleType.needs, l10n),
      ));
    }

    if (wants != null) {
      gap();
      barRows.add(_RoleBudgetGlanceRow(
        accentColor: accentColor,
        l10n: l10n,
        role: BudgetRoleType.wants,
        data: wants,
        label: _roleTitle(BudgetRoleType.wants, l10n),
      ));
    }

    if (goals != null) {
      gap();
      barRows.add(_RoleBudgetGlanceRow(
        accentColor: accentColor,
        l10n: l10n,
        role: BudgetRoleType.goals,
        data: goals,
        label: _roleTitle(BudgetRoleType.goals, l10n),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetExpiredBanner(),
        if (safeDaily != null && safeDaily > 0) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined,
                    color: accentColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.safeToSpendTodayBanner(
                      CurrencyFormatter.format(safeDaily,
                          currency: currency),
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                l10n.roleBudgetSectionTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const BudgetsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: accentColor),
              child: Text(l10n.budgets),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: barRows,
            ),
          ),
        ),
      ],
    );
  }
}

/// Where we are inside the budget period (0 … 1 along the runway bar).
double _elapsedThroughPeriodFrac(
  DateTime now,
  DateTime periodStart,
  DateTime periodEnd,
) {
  final totalMs = periodEnd.difference(periodStart).inMilliseconds;
  if (totalMs <= 0) return 1.0;
  if (now.isBefore(periodStart)) return 0.0;
  if (now.isAfter(periodEnd)) return 1.0;
  return (now.difference(periodStart).inMilliseconds / totalMs)
      .clamp(0.0, 1.0);
}

/// Period strip with border: grey base + **left-to-right fill** = share of budget **remaining**,
/// plus **Today** marker on the **calendar** axis (time through the period).
class _RolePeriodTimeline extends StatelessWidget {
  const _RolePeriodTimeline({
    required this.startDate,
    required this.endDate,
    required this.accentColor,
    required this.l10n,
    required this.remainingFraction,
    required this.runwayColor,
  });

  final DateTime startDate;
  final DateTime endDate;
  final Color accentColor;
  final AppLocalizations l10n;
  /// 0…1 of limit still available ([BudgetWithSpent.remaining] / limit).
  final double remainingFraction;
  /// Traffic-light color from spend pacing.
  final Color runwayColor;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final t = _elapsedThroughPeriodFrac(now, startDate, endDate);

    final dateStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.black54,
        );

    const hPad = 6.0;

    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(DateFormat('MMM d').format(startDate), style: dateStyle),
          Expanded(
            child: SizedBox(
              height: 40,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: _barHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LayoutBuilder(
                                builder: (context, inner) {
                                  final w = inner.maxWidth *
                                      remainingFraction.clamp(0.0, 1.0);
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ColoredBox(
                                          color: Colors.grey.shade200),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 350),
                                          curve: Curves.easeOutCubic,
                                          width: w,
                                          height: double.infinity,
                                          color: runwayColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(2 * t - 1, 1),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: _barHeight),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      l10n.today,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                    width: 2, height: 14, color: accentColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Text(DateFormat('MMM d').format(endDate), style: dateStyle),
        ],
      ),
    );
  }
}

class _RoleBudgetGlanceRow extends ConsumerWidget {
  const _RoleBudgetGlanceRow({
    required this.accentColor,
    required this.l10n,
    required this.role,
    required this.data,
    required this.label,
  });

  final Color accentColor;
  final AppLocalizations l10n;
  final BudgetRoleType role;
  final BudgetWithSpent data;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = data.budget.limitAmount;
    final spentFrac =
        limit > 0 ? (data.spent / limit).clamp(0.0, 999.0) : 0.0;

    double remainingFrac = 0;
    double pctLeft = 0;
    if (limit > 0) {
      remainingFrac =
          math.min(math.max(data.remaining / limit, 0.0), 1.0);
      pctLeft = (remainingFrac * 100).clamp(0.0, 100.0);
    }

    final color = RoleProgressSection._usageColor(spentFrac);
    final pctLabel = limit > 0
        ? l10n.percentLeftBudget(pctLeft.round().toString())
        : '—';

    final daysShown = math.max(data.daysRemaining, 0);
    final daysLabel = l10n.daysLeftInBudget(daysShown);

    final start = DateTime.fromMillisecondsSinceEpoch(data.budget.startDate);
    final end = DateTime.fromMillisecondsSinceEpoch(data.budget.endDate);

    return Semantics(
      label: '$label; $pctLabel; $daysLabel',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => BudgetFormScreen(
                  budget: data.budget,
                  existingCategoryIds: data.categoryIds,
                ),
              ),
            );
            if (context.mounted) {
              ref.read(budgetProvider.notifier).loadBudgets();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(role.icon, color: role.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                            ),
                          ),
                          Text(
                            pctLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black26,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        daysLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: limit > 0
                            ? '${CurrencyFormatter.format(data.remaining)} ${l10n.remainingLabel} ${l10n.leftOf(CurrencyFormatter.format(limit))}'
                            : l10n.budget,
                        preferBelow: false,
                        triggerMode: TooltipTriggerMode.longPress,
                        child: _RolePeriodTimeline(
                          startDate: start,
                          endDate: end,
                          accentColor: accentColor,
                          l10n: l10n,
                          remainingFraction: remainingFrac,
                          runwayColor: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
