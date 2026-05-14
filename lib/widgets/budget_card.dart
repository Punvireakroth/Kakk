import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../utils/currency_formatter.dart';

class BudgetCard extends StatelessWidget {
  final BudgetWithSpent budgetData;
  final String? accountName; // null means "All Accounts"
  final int categoryCount;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;
  final Color? accentColor;

  const BudgetCard({
    super.key,
    required this.budgetData,
    this.accountName,
    this.categoryCount = 0,
    this.onTap,
    this.onHistoryTap,
    this.accentColor,
  });

  // Default accent color (used as fallback)
  static const Color _defaultAccent = Color(0xFF6B7FD7);

  Color get _darkAccent => accentColor ?? _defaultAccent;
  Color get _cardColor => _darkAccent.withOpacity(0.15);

  @override
  Widget build(BuildContext context) {
    final budget = budgetData.budget;
    final startDate = DateTime.fromMillisecondsSinceEpoch(budget.startDate);
    final endDate = DateTime.fromMillisecondsSinceEpoch(budget.endDate);
    final now = DateTime.now();

    // Calculate timeline progress (how far through the budget period)
    final totalDays = endDate.difference(startDate).inDays;
    final daysPassed = now.difference(startDate).inDays;
    final timelineProgress = totalDays > 0
        ? (daysPassed / totalDays).clamp(0.0, 1.0)
        : 0.0;

    final themeAccent = Theme.of(context).colorScheme.primary;
    final progressAccent = accentColor ?? themeAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header section with solid background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget name and history icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          budget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onHistoryTap,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _darkAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history,
                            size: 20,
                            color: _darkAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Amount remaining
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(budgetData.remaining),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' left of ${CurrencyFormatter.format(budget.limitAmount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 12),
                  // Account and categories info
                  _buildTrackingInfo(),
                ],
              ),
            ),
            // Timeline section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Today marker + progress bar (stem cuts through bar like home)
                  SizedBox(
                    height: 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: progressAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment(
                            2 * timelineProgress.clamp(0.0, 1.0) - 1,
                            1,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _darkAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 22,
                                color: _darkAccent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Date labels and percentage
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('MMM d').format(startDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${budgetData.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d').format(endDate),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Daily spending allowance
                  Text(
                    _getDailyAllowanceText(),
                    style: TextStyle(fontSize: 13, color: _getStatusColor()),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (budgetData.isOverBudget) {
      return Colors.red.shade600;
    } else if (budgetData.isWarning) {
      return Colors.orange.shade700;
    }
    return Colors.black54;
  }

  String _getDailyAllowanceText() {
    if (budgetData.isOverBudget) {
      return 'Over budget by ${CurrencyFormatter.format(budgetData.spent - budgetData.budget.limitAmount)}';
    }
    if (budgetData.daysRemaining == 0) {
      return 'Budget period ended';
    }
    return 'You can spend ${CurrencyFormatter.format(budgetData.dailyAllowance)}/day for ${budgetData.daysRemaining} more days';
  }

  Widget _buildTrackingInfo() {
    final categoriesText = budgetData.categoryIds.isEmpty
        ? 'No categories'
        : '${budgetData.categoryIds.length} ${budgetData.categoryIds.length == 1 ? 'category' : 'categories'}';
    final accountText = budgetData.budget.tracksAllAccounts
        ? 'All Accounts'
        : (accountName ?? 'Specific Account');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                budgetData.budget.tracksAllAccounts
                    ? Icons.account_balance_wallet
                    : Icons.account_balance,
                size: 14,
                color: _darkAccent,
              ),
              const SizedBox(width: 4),
              Text(
                accountText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _darkAccent,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined, size: 14, color: _darkAccent),
              const SizedBox(width: 4),
              Text(
                categoriesText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _darkAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty budget card for adding new budgets
class AddBudgetCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddBudgetCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.add, size: 40, color: Colors.grey.shade400),
        ),
      ),
    );
  }
}
