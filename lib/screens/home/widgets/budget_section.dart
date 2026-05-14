import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';
import '../../budgets/budget_form_screen.dart';
import 'budget_expired_banner.dart';

class BudgetSection extends ConsumerWidget {
  const BudgetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final settings = ref.watch(settingsProvider);
    final accentColor = settings.accentColor;
    final l10n = AppLocalizations.of(context)!;
    final activeBudgets = budgetState.activeBudgets;

    return Column(
      children: [
        const BudgetExpiredBanner(),

        // Show active budget or create prompt
        if (activeBudgets.isEmpty)
          _buildCreateBudgetPrompt(context, ref, accentColor, l10n)
        else
          _buildActiveBudget(context, ref, activeBudgets, accentColor, l10n),
      ],
    );
  }

  Widget _buildCreateBudgetPrompt(
    BuildContext context,
    WidgetRef ref,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetFormScreen()),
        ).then((_) => ref.read(budgetProvider.notifier).loadBudgets());
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pie_chart_outline, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.setUpBudget,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.trackSpendingHabits,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBudget(
    BuildContext context,
    WidgetRef ref,
    List<BudgetWithSpent> activeBudgets,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        itemCount: activeBudgets.length,
        controller: PageController(viewportFraction: 1.0),
        itemBuilder: (context, index) {
          return _buildBudgetCard(
            context,
            ref,
            activeBudgets[index],
            accentColor,
            l10n,
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    BudgetWithSpent budgetData,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final budget = budgetData.budget;
    final startDate = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final now = DateTime.now();

    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = now.difference(startDate).inDays;
    final timelineProgress = totalDays > 0
        ? (daysPassed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BudgetFormScreen(
                budget: budget,
                existingCategoryIds: budgetData.categoryIds,
              ),
            ),
          ).then((_) => ref.read(budgetProvider.notifier).loadBudgets());
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(budget.name, budgetData, accentColor, l10n),
              const SizedBox(height: 12),
              _buildBalanceDisplay(budgetData, l10n),
              const SizedBox(height: 16),
              _buildTimeline(
                context,
                startDate,
                endDate,
                timelineProgress,
                accentColor,
                l10n,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getBudgetStatusText(budgetData, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    color: budgetData.isOverBudget
                        ? Colors.red.shade700
                        : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    String name,
    BudgetWithSpent budgetData,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    final accountText = budgetData.budget.tracksAllAccounts
        ? l10n.allAccounts
        : l10n.specificAccount;
    final categoryCount = budgetData.categoryIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 20, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  budgetData.budget.tracksAllAccounts
                      ? Icons.account_balance_wallet
                      : Icons.account_balance,
                  size: 12,
                  color: accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  accountText,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category_outlined, size: 12, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  l10n.categoryCount(categoryCount),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(
    BudgetWithSpent budgetData,
    AppLocalizations l10n,
  ) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: CurrencyFormatter.format(budgetData.remaining),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(
            text:
                ' ${l10n.leftOf(CurrencyFormatter.format(budgetData.budget.limitAmount))}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      softWrap: true,
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    double timelineProgress,
    Color accentColor,
    AppLocalizations l10n,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Text(
              DateFormat('MMM d').format(startDate),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accentColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Text(
              DateFormat('MMM d').format(endDate),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        Positioned(
          left:
              50 +
              (MediaQuery.of(context).size.width - 130) * timelineProgress -
              20,
          top: -20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
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
              Container(width: 2, height: 20, color: accentColor),
            ],
          ),
        ),
      ],
    );
  }

  String _getBudgetStatusText(
    BudgetWithSpent budgetData,
    AppLocalizations l10n,
  ) {
    if (budgetData.isOverBudget) {
      return l10n.overBudgetBy(
        CurrencyFormatter.format(
          budgetData.spent - budgetData.budget.limitAmount,
        ),
      );
    }
    if (budgetData.daysRemaining == 0) {
      return l10n.budgetPeriodEnded;
    }
    return l10n.dailySpendingAllowance(
      CurrencyFormatter.format(budgetData.dailyAllowance),
      budgetData.daysRemaining,
    );
  }
}
