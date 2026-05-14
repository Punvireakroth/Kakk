import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/budget_provider.dart';
import '../../utils/budget_role_type.dart';
import '../../utils/currency_formatter.dart';

/// Full-screen editor: split [incomeAmount] across Needs, Wants, and Goals (50/30/20 default).
class RoleAssignmentScreen extends ConsumerStatefulWidget {
  final double incomeAmount;
  final String currencyCode;
  final String? accountId;
  final int periodStartMs;
  final int periodEndMs;

  const RoleAssignmentScreen({
    super.key,
    required this.incomeAmount,
    required this.currencyCode,
    required this.accountId,
    required this.periodStartMs,
    required this.periodEndMs,
  });

  @override
  ConsumerState<RoleAssignmentScreen> createState() =>
      _RoleAssignmentScreenState();
}

class _RoleAssignmentScreenState extends ConsumerState<RoleAssignmentScreen> {
  late final TextEditingController _needsController;
  late final TextEditingController _wantsController;
  late final TextEditingController _goalsController;

  @override
  void initState() {
    super.initState();
    final inc = widget.incomeAmount;
    final decimals = CurrencyFormatter.getDecimalDigits(widget.currencyCode);
    String fmt(double v) => v.toStringAsFixed(decimals);
    _needsController = TextEditingController(text: fmt(inc * 0.50));
    _wantsController = TextEditingController(text: fmt(inc * 0.30));
    _goalsController = TextEditingController(text: fmt(inc * 0.20));
    _needsController.addListener(() => setState(() {}));
    _wantsController.addListener(() => setState(() {}));
    _goalsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _needsController.dispose();
    _wantsController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  double _parse(String raw) =>
      double.tryParse(raw.replaceAll(',', '').trim()) ?? 0.0;

  double get _needs => _parse(_needsController.text);
  double get _wants => _parse(_wantsController.text);
  double get _goals => _parse(_goalsController.text);

  double get _assigned => _needs + _wants + _goals;

  double get _remaining => widget.incomeAmount - _assigned;

  bool get _sumsMatch => _remaining.abs() < 0.015;

  Future<void> _onSave() async {
    if (!_sumsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Should add up to your income.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_needs <= 0 || _wants <= 0 || _goals <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each line needs a number above zero.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ok = await ref.read(budgetProvider.notifier).createRoleBudgets(
          accountId: widget.accountId,
          incomeAmount: widget.incomeAmount,
          needs: _needs,
          wants: _wants,
          goals: _goals,
          startDate: widget.periodStartMs,
          endDate: widget.periodEndMs,
        );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final err = ref.read(budgetProvider).error ?? 'Could not save role budgets';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = CurrencyFormatter.getCurrencySymbol(widget.currencyCode);
    final budgetLoading = ref.watch(budgetProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split income'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  CurrencyFormatter.format(
                    widget.incomeAmount,
                    currency: widget.currencyCode,
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Three amounts, same total.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _sumsMatch
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _sumsMatch
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sumsMatch ? Icons.check_circle_outline : Icons.info_outline,
                        color: _sumsMatch ? Colors.green.shade700 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _sumsMatch
                              ? 'Adds up.'
                              : _remaining > 0
                                  ? '${symbol}${_remaining.toStringAsFixed(2)} left'
                                  : '${symbol}${(-_remaining).toStringAsFixed(2)} over',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _sumsMatch
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _RoleRow(
                  label: BudgetRoleType.needs.displayName,
                  color: BudgetRoleType.needs.color,
                  controller: _needsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _needs,
                  currencyCode: widget.currencyCode,
                ),
                const SizedBox(height: 16),
                _RoleRow(
                  label: BudgetRoleType.wants.displayName,
                  color: BudgetRoleType.wants.color,
                  controller: _wantsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _wants,
                  currencyCode: widget.currencyCode,
                ),
                const SizedBox(height: 16),
                _RoleRow(
                  label: BudgetRoleType.goals.displayName,
                  color: BudgetRoleType.goals.color,
                  controller: _goalsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _goals,
                  currencyCode: widget.currencyCode,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: budgetLoading ? null : _onSave,
                  child: budgetLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final String label;
  final Color color;
  final TextEditingController controller;
  final double totalIncome;
  final double assigned;
  final String currencyCode;

  const _RoleRow({
    required this.label,
    required this.color,
    required this.controller,
    required this.totalIncome,
    required this.assigned,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        totalIncome > 0 ? (assigned / totalIncome).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText:
                '${CurrencyFormatter.getCurrencySymbol(currencyCode)} ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
        ),
      ],
    );
  }
}
