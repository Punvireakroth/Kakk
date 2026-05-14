import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/currency_formatter.dart';

/// Orange call-to-action when any non-archived budget has expired (renew / archive).
class BudgetExpiredBanner extends ConsumerWidget {
  const BudgetExpiredBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final expiredBudgets = budgetState.expiredBudgets;
    if (expiredBudgets.isEmpty) return const SizedBox.shrink();

    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;
    final firstExpired = expiredBudgets.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_off_outlined,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expiredBudgets.length == 1
                      ? l10n.budgetExpired(firstExpired.budget.name)
                      : l10n.budgetsExpired(expiredBudgets.length),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.renewOrArchive,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showBudgetRenewalSheet(
              context,
              ref,
              firstExpired,
              accentColor,
              l10n,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(l10n.action),
          ),
        ],
      ),
    );
  }
}

void showBudgetRenewalSheet(
  BuildContext context,
  WidgetRef ref,
  BudgetWithSpent budgetData,
  Color accentColor,
  AppLocalizations l10n,
) {
  final now = DateTime.now();
  final originalDuration =
      budgetData.budget.endDate - budgetData.budget.startDate;
  final newStartDate = DateTime(now.year, now.month, 1);
  final newEndDate =
      newStartDate.add(Duration(milliseconds: originalDuration));

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_off_outlined,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '"${budgetData.budget.name}" ${l10n.expired}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryRow(
                        l10n.spent,
                        CurrencyFormatter.format(budgetData.spent),
                        budgetData.isOverBudget ? Colors.red : Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        l10n.budget,
                        CurrencyFormatter.format(
                          budgetData.budget.limitAmount,
                        ),
                        null,
                      ),
                      const SizedBox(height: 8),
                      _summaryRow(
                        budgetData.isOverBudget ? l10n.overBy : l10n.saved,
                        CurrencyFormatter.format(
                          budgetData.isOverBudget
                              ? budgetData.spent -
                                  budgetData.budget.limitAmount
                              : budgetData.remaining,
                        ),
                        budgetData.isOverBudget ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(budgetProvider.notifier)
                              .archiveBudget(budgetData.budget.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.budgetArchived)),
                            );
                          }
                        },
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: Text(l10n.archive),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final success =
                              await ref.read(budgetProvider.notifier).renewBudget(
                                    budgetData,
                                    newStartDate:
                                        newStartDate.millisecondsSinceEpoch,
                                    newEndDate:
                                        newEndDate.millisecondsSinceEpoch,
                                  );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.budgetRenewed)),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(l10n.renew),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${l10n.newPeriod}: ${DateFormat('MMM d').format(newStartDate)} - ${DateFormat('MMM d').format(newEndDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _summaryRow(String label, String value, Color? valueColor) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.black54)),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: valueColor ?? Colors.black87,
        ),
      ),
    ],
  );
}
