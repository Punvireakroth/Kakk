import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ai_role_suggestion.dart';
import '../../providers/budget_provider.dart';
import '../../utils/budget_role_type.dart';
import '../../utils/currency_formatter.dart';
import 'role_assignment_screen.dart';

/// Full-screen AI proposal for Needs / Wants / Goals with editable amounts.
class AiRoleSuggestionScreen extends ConsumerStatefulWidget {
  final AiRoleSuggestion suggestion;
  final double incomeAmount;
  final String currencyCode;
  final String? accountId;
  final int periodStartMs;
  final int periodEndMs;

  const AiRoleSuggestionScreen({
    super.key,
    required this.suggestion,
    required this.incomeAmount,
    required this.currencyCode,
    required this.accountId,
    required this.periodStartMs,
    required this.periodEndMs,
  });

  @override
  ConsumerState<AiRoleSuggestionScreen> createState() =>
      _AiRoleSuggestionScreenState();
}

class _AiRoleSuggestionScreenState extends ConsumerState<AiRoleSuggestionScreen> {
  late final TextEditingController _needsController;
  late final TextEditingController _wantsController;
  late final TextEditingController _goalsController;

  @override
  void initState() {
    super.initState();
    final decimals =
        CurrencyFormatter.getDecimalDigits(widget.currencyCode);
    String fmt(double v) => v.toStringAsFixed(decimals);
    final s = widget.suggestion;
    _needsController = TextEditingController(text: fmt(s.needsAmount));
    _wantsController = TextEditingController(text: fmt(s.wantsAmount));
    _goalsController = TextEditingController(text: fmt(s.goalsAmount));
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

  double _stepForCurrency() =>
      CurrencyFormatter.getDecimalDigits(widget.currencyCode) == 0
          ? 1.0
          : 0.01;

  double _parse(String raw) =>
      double.tryParse(raw.replaceAll(',', '').trim()) ?? 0.0;

  double get _needs => _parse(_needsController.text);
  double get _wants => _parse(_wantsController.text);
  double get _goals => _parse(_goalsController.text);

  double get _assigned => _needs + _wants + _goals;
  double get _remaining => widget.incomeAmount - _assigned;
  bool get _sumsMatch => _remaining.abs() < 0.015;

  String _fmtDelta(double v) {
    final d = CurrencyFormatter.getDecimalDigits(widget.currencyCode);
    return v.toStringAsFixed(d);
  }

  void _bump(TextEditingController c, double delta) {
    final decimals =
        CurrencyFormatter.getDecimalDigits(widget.currencyCode);
    final cur = _parse(c.text);
    final next = (cur + delta).clamp(0.0, double.infinity);
    c.text = next.toStringAsFixed(decimals);
    c.selection =
        TextSelection.collapsed(offset: c.text.length);
  }

  Future<void> _onAcceptSave() async {
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
      final err =
          ref.read(budgetProvider).error ?? 'Could not save role budgets';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  void _onAdjust() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => RoleAssignmentScreen(
          incomeAmount: widget.incomeAmount,
          currencyCode: widget.currencyCode,
          accountId: widget.accountId,
          periodStartMs: widget.periodStartMs,
          periodEndMs: widget.periodEndMs,
          initialNeedsAmount: _needs,
          initialWantsAmount: _wants,
          initialGoalsAmount: _goals,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final symbol =
        CurrencyFormatter.getCurrencySymbol(widget.currencyCode);
    final budgetLoading = ref.watch(budgetProvider).isLoading;
    final s = widget.suggestion;
    final step = _stepForCurrency();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roleAiSuggestedSplitTitle),
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
                        _sumsMatch
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: _sumsMatch
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _sumsMatch
                              ? 'Adds up.'
                              : _remaining > 0
                                  ? '$symbol${_fmtDelta(_remaining)} left'
                                  : '$symbol${_fmtDelta(-_remaining)} over',
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
                _AiRoleRow(
                  label: BudgetRoleType.needs.displayName,
                  color: BudgetRoleType.needs.color,
                  reason: s.needsReason,
                  controller: _needsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _needs,
                  currencyCode: widget.currencyCode,
                  step: step,
                  onDecrement: () => _bump(_needsController, -step),
                  onIncrement: () => _bump(_needsController, step),
                ),
                const SizedBox(height: 16),
                _AiRoleRow(
                  label: BudgetRoleType.wants.displayName,
                  color: BudgetRoleType.wants.color,
                  reason: s.wantsReason,
                  controller: _wantsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _wants,
                  currencyCode: widget.currencyCode,
                  step: step,
                  onDecrement: () => _bump(_wantsController, -step),
                  onIncrement: () => _bump(_wantsController, step),
                ),
                const SizedBox(height: 16),
                _AiRoleRow(
                  label: BudgetRoleType.goals.displayName,
                  color: BudgetRoleType.goals.color,
                  reason: s.goalsReason,
                  controller: _goalsController,
                  totalIncome: widget.incomeAmount,
                  assigned: _goals,
                  currencyCode: widget.currencyCode,
                  step: step,
                  onDecrement: () => _bump(_goalsController, -step),
                  onIncrement: () => _bump(_goalsController, step),
                ),
                const SizedBox(height: 24),
                Text(
                  s.isFallback
                      ? l10n.roleAiSuggestionFooterDefaultSplit
                      : l10n.roleAiSuggestionFooterFromHistory,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: budgetLoading ? null : _onAcceptSave,
                      child: budgetLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.roleAcceptAndSave),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: budgetLoading ? null : _onAdjust,
                      child: Text(l10n.roleAdjustManually),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiRoleRow extends StatelessWidget {
  final String label;
  final Color color;
  final String reason;
  final TextEditingController controller;
  final double totalIncome;
  final double assigned;
  final String currencyCode;
  final double step;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _AiRoleRow({
    required this.label,
    required this.color,
    required this.reason,
    required this.controller,
    required this.totalIncome,
    required this.assigned,
    required this.currencyCode,
    required this.step,
    required this.onDecrement,
    required this.onIncrement,
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
        const SizedBox(height: 6),
        Text(
          reason,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton.filledTonal(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove),
              tooltip: step >= 1 ? '-${step.toInt()}' : '-$step',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText:
                      '${CurrencyFormatter.getCurrencySymbol(currencyCode)} ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onIncrement,
              icon: const Icon(Icons.add),
              tooltip: step >= 1 ? '+${step.toInt()}' : '+$step',
            ),
          ],
        ),
      ],
    );
  }
}
